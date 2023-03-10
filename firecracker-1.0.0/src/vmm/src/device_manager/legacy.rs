// Copyright 2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
//
// Portions Copyright 2017 The Chromium OS Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the THIRD-PARTY file.
#![cfg(target_arch = "x86_64")]

use devices::legacy::SerialDevice;
use devices::legacy::SerialEventsWrapper;
use libc::EFD_NONBLOCK;
use logger::METRICS;
use std::fmt;
use std::sync::{Arc, Mutex};

use devices::legacy::EventFdTrigger;
use kvm_ioctls::VmFd;
use utils::eventfd::EventFd;
use vm_superio::Serial;

/// Errors corresponding to the `PortIODeviceManager`.
#[derive(Debug)]
pub enum Error {
    /// Cannot add legacy device to Bus.
    BusError(devices::BusError),
    /// Cannot create EventFd.
    EventFd(std::io::Error),
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        use self::Error::*;

        match *self {
            BusError(ref err) => write!(f, "Failed to add legacy device to Bus: {}", err),
            EventFd(ref err) => write!(f, "Failed to create EventFd: {}", err),
        }
    }
}

type Result<T> = ::std::result::Result<T, Error>;

fn create_serial(com_event: EventFdTrigger) -> Result<Arc<Mutex<SerialDevice>>> {
    let serial_device = Arc::new(Mutex::new(SerialDevice {
        serial: Serial::with_events(
            com_event.try_clone().map_err(Error::EventFd)?,
            SerialEventsWrapper {
                metrics: METRICS.uart.clone(),
                buffer_ready_event_fd: None,
            },
            Box::new(std::io::sink()),
        ),
        input: None,
    }));

    Ok(serial_device)
}

/// The `PortIODeviceManager` is a wrapper that is used for registering legacy devices
/// on an I/O Bus. It currently manages the uart and i8042 devices.
/// The `LegacyDeviceManger` should be initialized only by using the constructor.
pub struct PortIODeviceManager {
    pub io_bus: devices::Bus,
    pub stdio_serial: Arc<Mutex<SerialDevice>>,
    pub i8042: Arc<Mutex<devices::legacy::I8042Device>>,

    pub com_evt_1_3: EventFdTrigger,
    pub com_evt_2_4: EventFdTrigger,
    pub kbd_evt: EventFd,
}

impl PortIODeviceManager {
    /// Create a new DeviceManager handling legacy devices (uart, i8042).
    pub fn new(serial: Arc<Mutex<SerialDevice>>, i8042_reset_evfd: EventFd) -> Result<Self> {
        let io_bus = devices::Bus::new();
        let com_evt_1_3 = serial
            .lock()
            .expect("Poisoned lock")
            .serial
            .interrupt_evt()
            .try_clone()
            .map_err(Error::EventFd)?;
        let com_evt_2_4 = EventFdTrigger::new(EventFd::new(EFD_NONBLOCK).map_err(Error::EventFd)?);
        let kbd_evt = EventFd::new(libc::EFD_NONBLOCK).map_err(Error::EventFd)?;

        let i8042 = Arc::new(Mutex::new(devices::legacy::I8042Device::new(
            i8042_reset_evfd,
            kbd_evt.try_clone().map_err(Error::EventFd)?,
        )));

        Ok(PortIODeviceManager {
            io_bus,
            stdio_serial: serial,
            i8042,
            com_evt_1_3,
            com_evt_2_4,
            kbd_evt,
        })
    }

    /// Register supported legacy devices.
    pub fn register_devices(&mut self, vm_fd: &VmFd) -> Result<()> {
        let serial_2_4 = create_serial(self.com_evt_2_4.try_clone().map_err(Error::EventFd)?)?;
        let serial_1_3 = create_serial(self.com_evt_1_3.try_clone().map_err(Error::EventFd)?)?;
        self.io_bus
            .insert(self.stdio_serial.clone(), 0x3f8, 0x8)
            .map_err(Error::BusError)?;
        self.io_bus
            .insert(serial_2_4.clone(), 0x2f8, 0x8)
            .map_err(Error::BusError)?;
        self.io_bus
            .insert(serial_1_3.clone(), 0x3e8, 0x8)
            .map_err(Error::BusError)?;
        self.io_bus
            .insert(serial_2_4, 0x2e8, 0x8)
            .map_err(Error::BusError)?;
        self.io_bus
            .insert(self.i8042.clone(), 0x060, 0x5)
            .map_err(Error::BusError)?;

        vm_fd
            .register_irqfd(&self.com_evt_1_3, 4)
            .map_err(|e| Error::EventFd(std::io::Error::from_raw_os_error(e.errno())))?;
        vm_fd
            .register_irqfd(&self.com_evt_2_4, 3)
            .map_err(|e| Error::EventFd(std::io::Error::from_raw_os_error(e.errno())))?;
        vm_fd
            .register_irqfd(&self.kbd_evt, 1)
            .map_err(|e| Error::EventFd(std::io::Error::from_raw_os_error(e.errno())))?;

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use vm_memory::GuestAddress;

    #[test]
    fn test_register_legacy_devices() {
        let guest_mem =
            vm_memory::test_utils::create_anon_guest_memory(&[(GuestAddress(0x0), 0x1000)], false)
                .unwrap();
        let mut vm = crate::builder::setup_kvm_vm(&guest_mem, false).unwrap();
        crate::builder::setup_interrupt_controller(&mut vm).unwrap();
        let mut ldm = PortIODeviceManager::new(
            create_serial(EventFdTrigger::new(EventFd::new(EFD_NONBLOCK).unwrap())).unwrap(),
            EventFd::new(libc::EFD_NONBLOCK).unwrap(),
        )
        .unwrap();
        assert!(ldm.register_devices(vm.fd()).is_ok());
    }

    #[test]
    fn test_debug_error() {
        assert_eq!(
            format!("{}", Error::BusError(devices::BusError::Overlap)),
            format!(
                "Failed to add legacy device to Bus: {}",
                devices::BusError::Overlap
            )
        );
        assert_eq!(
            format!("{}", Error::EventFd(std::io::Error::from_raw_os_error(1))),
            format!(
                "Failed to create EventFd: {}",
                std::io::Error::from_raw_os_error(1)
            )
        );
    }
}
