// Copyright (c) 2026 YiraSan
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

const std = @import("std");
const options = @import("options");
const builtin = @import("builtin");

pub const protocol_revision: usize = options.revision;

pub const Arch = enum {
    aarch64,
    loongarch64,
    riscv64,
    x86_64,
};

pub const arch: Arch = switch (builtin.target.cpu.arch) {
    .aarch64 => .aarch64,
    .loongarch64 => .loongarch64,
    .x86_64 => .x86_64,
    .riscv64 => .riscv64,
    else => |arch_tag| @compileError("Unsupported architecture: " ++ @tagName(arch_tag)),
};

fn id(a: u64, b: u64) [4]u64 {
    return .{ 0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, a, b };
}

fn LiminePtr(comptime Type: type) type {
    return if (options.no_pointers) u64 else Type;
}

const init_pointer = if (options.no_pointers)
    0
else
    null;

pub const RequestsStartMarker = extern struct {
    marker: [4]u64 = .{
        0xf6b8f4b39de7d1ae,
        0xfab91a6940fcb9cf,
        0x785c6ed015d3e316,
        0x181e920a7852b9d9,
    },
};

pub const RequestsEndMarker = extern struct {
    marker: [2]u64 = .{ 0xadc0e0531bb10d03, 0x9572709f31764c62 },
};

pub const BaseRevision = extern struct {
    magic: [2]u64 = .{ 0xf9562b2d5c95a6c8, 0x6a7b384944536bdc },
    revision: u64,

    pub fn init(revision: u64) @This() {
        return .{ .revision = revision };
    }

    pub fn loadedRevision(self: @This()) u64 {
        return self.magic[1];
    }

    pub fn isValid(self: @This()) bool {
        return self.magic[1] != 0x6a7b384944536bdc;
    }

    pub fn isSupported(self: @This()) bool {
        return self.revision == 0;
    }
};

pub const Uuid = extern struct {
    a: u32,
    b: u16,
    c: u16,
    d: [8]u8,
};

pub const MediaType = enum(u32) {
    generic = 0,
    optical = 1,
    tftp = 2,
    _,
};

const LimineFileV1 = extern struct {
    revision: u64,
    address: LiminePtr(*align(4096) anyopaque),
    size: u64,
    path: LiminePtr([*:0]u8),
    cmdline: LiminePtr([*:0]u8),
    media_type: MediaType,
    unused: u32,
    tftp_ip: u32,
    tftp_port: u32,
    partition_index: u32,
    mbr_disk_id: u32,
    gpt_disk_uuid: Uuid,
    gpt_part_uuid: Uuid,
    part_uuid: Uuid,
};

const LimineFileV2 = extern struct {
    revision: u64,
    address: LiminePtr(*align(4096) anyopaque),
    size: u64,
    path: LiminePtr([*:0]u8),
    string: LiminePtr([*:0]u8),
    media_type: MediaType,
    unused: u32,
    tftp_ipv4: [4]u8,
    tftp_port: u32,
    partition_index: u32,
    mbr_disk_id: u32,
    gpt_disk_uuid: Uuid,
    gpt_part_uuid: Uuid,
    part_uuid: Uuid,
};

pub const File = if (protocol_revision >= 3)
    LimineFileV2
else
    LimineFileV1;

// Boot info

pub const BootloaderInfoResponse = extern struct {
    revision: u64,
    name: LiminePtr([*:0]u8),
    version: LiminePtr([*:0]u8),
};

pub const BootloaderInfoRequest = extern struct {
    id: [4]u64 = id(0xf55038d8e2a1202f, 0x279426fcf5f59740),
    revision: u64 = 0,
    response: LiminePtr(?*BootloaderInfoResponse) = init_pointer,
};

// Executable command line

pub const ExecutableCmdlineResponse = extern struct {
    revision: u64,
    cmdline: LiminePtr([*:0]u8),
};

pub const ExecutableCmdlineRequest = extern struct {
    id: [4]u64 = id(0x4b161536e598651e, 0xb390ad4a2f1f303a),
    revision: u64 = 0,
    response: LiminePtr(?*ExecutableCmdlineResponse) = init_pointer,
};

// Firmware type

pub const FirmwareType = enum(u64) {
    x86_bios = 0,
    efi32 = 1,
    efi64 = 2,
    sbi = 3,
    _,
};

pub const FirmwareTypeResponse = extern struct {
    revision: u64,
    firmware_type: FirmwareType,
};

pub const FirmwareTypeRequest = extern struct {
    id: [4]u64 = id(0x8c2f75d90bef28a8, 0x7045a4688eac00c3),
    revision: u64 = 0,
    response: LiminePtr(?*FirmwareTypeResponse) = init_pointer,
};

// Stack size

pub const StackSizeResponse = extern struct {
    revision: u64,
};

pub const StackSizeRequest = extern struct {
    id: [4]u64 = id(0x224ef0460a8e8926, 0xe1cb0fc25f46ea3d),
    revision: u64 = 0,
    response: LiminePtr(?*StackSizeResponse) = init_pointer,
    stack_size: u64,
};

// HHDM

pub const HhdmResponse = extern struct {
    revision: u64,
    offset: u64,
};

pub const HhdmRequest = extern struct {
    id: [4]u64 = id(0x48dcf1cb8ad2b852, 0x63984e959a98244b),
    revision: u64 = 0,
    response: LiminePtr(?*HhdmResponse) = init_pointer,
};

// Framebuffer

pub const FramebufferMemoryModel = enum(u8) {
    rgb = 1,
    _,
};

pub const VideoMode = extern struct {
    pitch: u64,
    width: u64,
    height: u64,
    bpp: u16,
    memory_model: FramebufferMemoryModel,
    red_mask_size: u8,
    red_mask_shift: u8,
    green_mask_size: u8,
    green_mask_shift: u8,
    blue_mask_size: u8,
    blue_mask_shift: u8,
};

pub const Framebuffer = extern struct {
    address: LiminePtr(*anyopaque),
    width: u64,
    height: u64,
    pitch: u64,
    bpp: u16,
    memory_model: FramebufferMemoryModel,
    red_mask_size: u8,
    red_mask_shift: u8,
    green_mask_size: u8,
    green_mask_shift: u8,
    blue_mask_size: u8,
    blue_mask_shift: u8,
    unused: [7]u8 = undefined,
    edid_size: u64,
    edid: LiminePtr(?*anyopaque),
    // Response revision 1
    mode_count: u64,
    modes: LiminePtr([*]*VideoMode),

    pub fn getEdid(self: @This()) ?[]u8 {
        if (self.edid_size == 0 or self.edid == null) {
            return null;
        }
        const ptr: [*]u8 = @ptrCast(self.edid.?);
        return ptr[0..self.edid_size];
    }

    /// Helper function to retrieve a slice of the modes array.
    /// This function is only available since revision 1 of the response and
    /// will return an error if called with an older response. This is to
    /// prevent the user from possibly accessing uninitialized memory.
    pub fn getModes(self: @This(), response: *FramebufferResponse) ![]*VideoMode {
        if (response.revision < 1) {
            return error.NotSupported;
        }
        return self.modes[0..self.mode_count];
    }
};

pub const FramebufferResponse = extern struct {
    revision: u64,
    framebuffer_count: u64,
    framebuffers: LiminePtr(?[*]*Framebuffer),

    /// Helper function to retrieve a slice of the framebuffers array.
    /// This function will return null if the framebuffer count is 0 or if
    /// the framebuffers pointer is null.
    pub fn getFramebuffers(self: @This()) []*Framebuffer {
        if (self.framebuffer_count == 0 or self.framebuffers == null) {
            return &.{};
        }
        return self.framebuffers.?[0..self.framebuffer_count];
    }
};

pub const FramebufferRequest = extern struct {
    id: [4]u64 = id(0x9d5827dcd881dd75, 0xa3148604f6fab11b),
    revision: u64 = 1,
    response: LiminePtr(?*FramebufferResponse) = init_pointer,
};

// Paging mode

pub const PagingMode = switch (arch) {
    .x86_64 => enum(u64) {
        @"4lvl",
        @"5lvl",
        _,

        const min: @This() = .@"4lvl";
        const max: @This() = .@"5lvl";
        const default: @This() = .@"4lvl";
    },
    .aarch64 => enum(u64) {
        @"4lvl",
        @"5lvl",
        _,

        const min: @This() = .@"4lvl";
        const max: @This() = .@"5lvl";
        const default: @This() = .@"4lvl";
    },
    .riscv64 => enum(u64) {
        sv39,
        sv48,
        sv57,
        _,

        const min: @This() = .sv39;
        const max: @This() = .sv57;
        const default: @This() = .sv48;
    },
    .loongarch64 => enum(u64) {
        @"4lvl",
        _,

        const min: @This() = .@"4lvl";
        const max: @This() = .@"4lvl";
        const default: @This() = .@"4lvl";
    },
};

pub const PagingModeResponse = extern struct {
    revision: u64,
    mode: PagingMode,
};

pub const PagingModeRequest = extern struct {
    id: [4]u64 = id(0x95c1a0edab0944cb, 0xa4e5cb3842f7488a),
    revision: u64 = 0,
    response: LiminePtr(?*PagingModeResponse) = init_pointer,
    mode: PagingMode = .default,
    max_mode: PagingMode = .max,
    min_mode: PagingMode = .min,
};

// MP

pub const GotoAddress = *const fn (*MpInfo) callconv(.c) void;

pub const MpRequestFlags = packed struct(u64) {
    /// Enable x2APIC, if possible. x86-64 only; ignored on other archs.
    x86_64_x2apic: bool = false,
    reserved: u63 = 0,
};

const MpResponseFlags = switch (arch) {
    .x86_64 => packed struct(u32) {
        /// Set by the bootloader if x2APIC was successfully enabled.
        x86_64_x2apic: bool = false,
        reserved: u31 = 0,
    },
    // "Always zero" on these architectures per the spec.
    .aarch64, .riscv64, .loongarch64 => u64,
};

pub const MpInfo = switch (arch) {
    .x86_64 => extern struct {
        processor_id: u32,
        lapic_id: u32,
        reserved: u64,
        goto_address: LiminePtr(?GotoAddress),
        extra_argument: u64,
    },
    .aarch64 => extern struct {
        processor_id: u32,
        reserved1: u32 = 0,
        mpidr: u64,
        reserved: u64,
        goto_address: LiminePtr(?GotoAddress),
        extra_argument: u64,
    },
    .riscv64 => extern struct {
        processor_id: u64,
        hartid: u64,
        reserved: u64,
        goto_address: LiminePtr(?GotoAddress),
        extra_argument: u64,
    },
    .loongarch64 => extern struct {
        processor_id: u64,
        phys_id: u64,
        reserved: u64,
        goto_address: LiminePtr(?GotoAddress),
        extra_argument: u64,
    },
};

pub const MpResponse = switch (arch) {
    .x86_64 => extern struct {
        revision: u64,
        flags: MpResponseFlags,
        bsp_lapic_id: u32,
        cpu_count: u64,
        cpus: LiminePtr(?[*]*MpInfo),

        /// Helper function to retrieve a slice of the CPUs array.
        /// This function will return null if the CPU count is 0 or if
        /// the CPUs pointer is null.
        pub fn getCpus(self: @This()) []*MpInfo {
            if (self.cpu_count == 0 or self.cpus == null) {
                return &.{};
            }
            return self.cpus.?[0..self.cpu_count];
        }
    },
    .aarch64 => extern struct {
        revision: u64,
        flags: MpResponseFlags,
        bsp_mpidr: u64,
        cpu_count: u64,
        cpus: LiminePtr(?[*]*MpInfo),

        pub fn getCpus(self: @This()) []*MpInfo {
            if (self.cpu_count == 0 or self.cpus == null) {
                return &.{};
            }
            return self.cpus.?[0..self.cpu_count];
        }
    },
    .riscv64 => extern struct {
        revision: u64,
        flags: MpResponseFlags,
        bsp_hartid: u64,
        cpu_count: u64,
        cpus: LiminePtr(?[*]*MpInfo),

        pub fn getCpus(self: @This()) []*MpInfo {
            if (self.cpu_count == 0 or self.cpus == null) {
                return &.{};
            }
            return self.cpus.?[0..self.cpu_count];
        }
    },
    .loongarch64 => extern struct {
        revision: u64,
        flags: MpResponseFlags,
        bsp_phys_id: u64,
        cpu_count: u64,
        cpus: LiminePtr(?[*]*MpInfo),

        pub fn getCpus(self: @This()) []*MpInfo {
            if (self.cpu_count == 0 or self.cpus == null) {
                return &.{};
            }
            return self.cpus.?[0..self.cpu_count];
        }
    },
};

pub const MpRequest = extern struct {
    id: [4]u64 = id(0x95a67b819a1b857e, 0xa0b61b723b6a73e0),
    revision: u64 = 0,
    response: LiminePtr(?*MpResponse) = init_pointer,
    flags: MpRequestFlags = .{},
};

// Memory map

const MemoryMapTypeV1 = enum(u64) {
    usable = 0,
    reserved = 1,
    acpi_reclaimable = 2,
    acpi_nvs = 3,
    bad_memory = 4,
    bootloader_reclaimable = 5,
    kernel_and_modules = 6,
    framebuffer = 7,
    _,
};

const MemoryMapTypeV2 = enum(u64) {
    usable = 0,
    reserved = 1,
    acpi_reclaimable = 2,
    acpi_nvs = 3,
    bad_memory = 4,
    bootloader_reclaimable = 5,
    executable_and_modules = 6,
    framebuffer = 7,
    _,
};

// Base revision 4+: adds LIMINE_MEMMAP_RESERVED_MAPPED.
const MemoryMapTypeV4 = enum(u64) {
    usable = 0,
    reserved = 1,
    acpi_reclaimable = 2,
    acpi_nvs = 3,
    bad_memory = 4,
    bootloader_reclaimable = 5,
    executable_and_modules = 6,
    framebuffer = 7,
    reserved_mapped = 8,
    _,
};

pub const MemoryMapType = if (protocol_revision >= 4)
    MemoryMapTypeV4
else if (protocol_revision >= 2)
    MemoryMapTypeV2
else
    MemoryMapTypeV1;

pub const MemoryMapEntry = extern struct {
    base: u64,
    length: u64,
    type: MemoryMapType,
};

pub const MemoryMapResponse = extern struct {
    revision: u64,
    entry_count: u64,
    entries: LiminePtr(?[*]*MemoryMapEntry),

    /// Helper function to retrieve a slice of the entries array.
    /// This function will return null if the entry count is 0 or if
    /// the entries pointer is null.
    pub fn getEntries(self: @This()) []*MemoryMapEntry {
        if (self.entry_count == 0 or self.entries == null) {
            return &.{};
        }
        return self.entries.?[0..self.entry_count];
    }
};

pub const MemoryMapRequest = extern struct {
    id: [4]u64 = id(0x67cf3d9d378a806f, 0xe304acdfc50c3c62),
    revision: u64 = 0,
    response: LiminePtr(?*MemoryMapResponse) = init_pointer,
};

// Entry point

// The C typedef is `void (*)(void)`; in practice the executable never
// returns from here, but the ABI contract itself doesn't claim `noreturn`.
pub const EntryPoint = *const fn () callconv(.c) void;

pub const EntryPointResponse = extern struct {
    revision: u64,
};

pub const EntryPointRequest = extern struct {
    id: [4]u64 = id(0x13d86c035a1cd3e1, 0x2b0caa89d8f3026a),
    revision: u64 = 0,
    response: LiminePtr(?*EntryPointResponse) = init_pointer,
    entry: LiminePtr(EntryPoint),
};

pub const ExecutableFileResponse = extern struct {
    revision: u64,
    executable_file: LiminePtr(*File),
};

pub const ExecutableFileRequest = extern struct {
    id: [4]u64 = id(0xad97e90e83f1ed67, 0x31eb5d1c5ff23b69),
    revision: u64 = 0,
    response: LiminePtr(?*ExecutableFileResponse) = init_pointer,
};

// Module

pub const InternalModuleFlag = packed struct(u64) {
    required: bool,
    compressed: bool,
    reserved: u62 = 0,
};

const InternalModuleV1 = extern struct {
    path: LiminePtr([*:0]const u8),
    cmdline: LiminePtr([*:0]const u8),
    flags: InternalModuleFlag,
};

const InternalModuleV2 = extern struct {
    path: LiminePtr([*:0]const u8),
    string: LiminePtr([*:0]const u8),
    flags: InternalModuleFlag,
};

pub const InternalModule = if (protocol_revision >= 3)
    InternalModuleV2
else
    InternalModuleV1;

pub const ModuleResponse = extern struct {
    revision: u64,
    module_count: u64,
    modules: LiminePtr(?[*]*File),

    /// Helper function to retrieve a slice of the modules array.
    /// This function will return null if the module count is 0 or if
    /// the modules pointer is null.
    pub fn getModules(self: @This()) []*File {
        if (self.module_count == 0 or self.modules == null) {
            return &.{};
        }
        return self.modules.?[0..self.module_count];
    }
};

pub const ModuleRequest = extern struct {
    id: [4]u64 = id(0x3e7e279702be32af, 0xca1c4f3bd1280cee),
    revision: u64 = 1,
    response: LiminePtr(?*ModuleResponse) = init_pointer,
    // Request revision 1
    internal_module_count: u64 = 0,
    internal_modules: LiminePtr(?[*]const *const InternalModule) =
        if (options.no_pointers) 0 else null,
};

// RSDP
//
// Address is physical for base revision 3 only; virtual (HHDM) for every
// other base revision, including 4 and above.

const RsdpResponseVirtual = extern struct {
    revision: u64,
    address: LiminePtr(*anyopaque),
};

const RsdpResponsePhysical = extern struct {
    revision: u64,
    address: u64,
};

pub const RsdpResponse = if (protocol_revision == 3)
    RsdpResponsePhysical
else
    RsdpResponseVirtual;

pub const RsdpRequest = extern struct {
    id: [4]u64 = id(0xc5e77b6b397e7b43, 0x27637845accdcf3c),
    revision: u64 = 0,
    response: LiminePtr(?*RsdpResponse) = init_pointer,
};

// SMBIOS
//
// Entry point addresses are physical for base revisions 3 and 4 only;
// virtual (HHDM) again from base revision 5 onwards.

const SmBiosResponseVirtual = extern struct {
    revision: u64,
    entry_32: LiminePtr(?*anyopaque),
    entry_64: LiminePtr(?*anyopaque),
};

const SmBiosResponsePhysical = extern struct {
    revision: u64,
    entry_32: u64,
    entry_64: u64,
};

pub const SmBiosResponse = if (protocol_revision >= 3 and protocol_revision <= 4)
    SmBiosResponsePhysical
else
    SmBiosResponseVirtual;

pub const SmBiosRequest = extern struct {
    id: [4]u64 = id(0x9e9046f11e095391, 0xaa4a520fefbde5ee),
    revision: u64 = 0,
    response: LiminePtr(?*SmBiosResponse) = init_pointer,
};

// EFI system table
//
// Address is physical for base revisions 3 and 4 only; virtual (HHDM)
// again from base revision 5 onwards.

const EfiSystemTableResponseVirtual = extern struct {
    revision: u64,
    address: LiminePtr(?*std.os.uefi.tables.SystemTable),
};

const EfiSystemTableResponsePhysical = extern struct {
    revision: u64,
    address: u64,
};

pub const EfiSystemTableResponse = if (protocol_revision >= 3 and protocol_revision <= 4)
    EfiSystemTableResponsePhysical
else
    EfiSystemTableResponseVirtual;

pub const EfiSystemTableRequest = extern struct {
    id: [4]u64 = id(0x5ceba5163eaaf6d6, 0x0a6981610cf65fcc),
    revision: u64 = 0,
    response: LiminePtr(?*EfiSystemTableResponse) = init_pointer,
};

// TPM Event Log

pub const TpmEventLogFormat = enum(u64) {
    tcg_1_2 = 1,
    tcg_2 = 2,
    _,
};

pub const TpmEventLogResponse = extern struct {
    revision: u64,
    format: TpmEventLogFormat,
    size: u64,
    address: LiminePtr(?*anyopaque),

    /// Helper function to retrieve the raw event log as a slice.
    /// Returns null if no event log was captured.
    pub fn getEventLog(self: @This()) ?[]u8 {
        if (self.size == 0 or self.address == null) {
            return null;
        }
        const ptr: [*]u8 = @ptrCast(self.address.?);
        return ptr[0..self.size];
    }
};

pub const TpmEventLogRequest = extern struct {
    id: [4]u64 = id(0x98e094fc7e76e979, 0xee8d8775c54e1d1f),
    revision: u64 = 0,
    response: LiminePtr(?*TpmEventLogResponse) = init_pointer,
};

// EFI memory map

pub const EfiMemoryMapResponse = extern struct {
    revision: u64,
    memmap: LiminePtr(*anyopaque),
    memmap_size: u64,
    desc_size: u64,
    desc_version: u64,
};

pub const EfiMemoryMapRequest = extern struct {
    id: [4]u64 = id(0x7df62a431d6872d5, 0xa4fcdfb3e57306c8),
    revision: u64 = 0,
    response: LiminePtr(?*EfiMemoryMapResponse) = init_pointer,
};

// Date at boot (formerly Boot time; the old naming has been dropped)

pub const DateAtBootResponse = extern struct {
    revision: u64,
    timestamp: i64,
};

pub const DateAtBootRequest = extern struct {
    id: [4]u64 = id(0x502746e184c088aa, 0xfbc5ec83e6327893),
    revision: u64 = 0,
    response: LiminePtr(?*DateAtBootResponse) = init_pointer,
};

// Executable address (formerly Kernel address; the old naming has been dropped)

pub const ExecutableAddressResponse = extern struct {
    revision: u64,
    physical_base: u64,
    virtual_base: u64,
};

pub const ExecutableAddressRequest = extern struct {
    id: [4]u64 = id(0x71ba76863cc55f63, 0xb2644a48c516a487),
    revision: u64 = 0,
    response: LiminePtr(?*ExecutableAddressResponse) = init_pointer,
};

// Device Tree Blob

pub const DtbResponse = extern struct {
    revision: u64,
    dtb_ptr: LiminePtr(*anyopaque),
};

pub const DtbRequest = extern struct {
    id: [4]u64 = id(0xb40ddb48fb54bac7, 0x545081493f81ffb7),
    revision: u64 = 0,
    response: LiminePtr(?*DtbResponse) = init_pointer,
};

// RISC-V Boot Hart ID

pub const RiscvBootHartIdResponse = extern struct {
    revision: u64,
    bsp_hartid: u64,
};

pub const RiscvBootHartIdRequest = extern struct {
    id: [4]u64 = id(0x1369359f025525f9, 0x2ff2a56178391bb6),
    revision: u64 = 0,
    response: LiminePtr(?*RiscvBootHartIdResponse) = init_pointer,
};

// Bootloader performance

pub const BootloaderPerformanceResponse = extern struct {
    revision: u64,
    /// Time of system reset in microseconds, relative to an arbitrary point
    /// in the past. May be assumed to be 0 if the bootloader can't or
    /// doesn't know the time of system reset.
    reset_usec: u64,
    /// Time of bootloader initialisation in microseconds, relative to the
    /// same arbitrary point as `reset_usec`.
    init_usec: u64,
    /// Time of executable handoff in microseconds, relative to the same
    /// arbitrary point as `reset_usec`.
    exec_usec: u64,
};

pub const BootloaderPerformanceRequest = extern struct {
    id: [4]u64 = id(0x6b50ad9bf36d13ad, 0xdc4c7e88fc759e17),
    revision: u64 = 0,
    response: LiminePtr(?*BootloaderPerformanceResponse) = init_pointer,
};

// x86-64 Keep IOMMU
//
// From base revision 5 onwards, the bootloader is mandated to disable any
// active Intel VT-d / AMD-Vi IOMMUs before handoff, unless this feature is
// requested. No response is provided on non-x86-64 platforms.

pub const X86_64KeepIommuResponse = extern struct {
    revision: u64,
};

pub const X86_64KeepIommuRequest = extern struct {
    id: [4]u64 = id(0x8ebaabe51f490179, 0x2aa86a59ffb4ab0f),
    revision: u64 = 0,
    response: LiminePtr(?*X86_64KeepIommuResponse) = init_pointer,
};

// TSC (Timestamp Counter) Frequency
//
// Frequency, in Hz, of the counter read by RDTSC (x86-64), CNTPCT_EL0
// (aarch64), RDTIME (riscv64), or RDTIME.D (loongarch64).

pub const TscFrequencyResponse = extern struct {
    revision: u64,
    frequency: u64,
};

pub const TscFrequencyRequest = extern struct {
    id: [4]u64 = id(0x10f2ee1d87d195e4, 0xf747a2b78f6ddb31),
    revision: u64 = 0,
    response: LiminePtr(?*TscFrequencyResponse) = init_pointer,
};

// Flanterm FB Init Params
//
// Requires the Framebuffer feature to also be requested. Entries correspond
// by index to framebuffers in the Framebuffer response; a zeroed entry means
// the corresponding framebuffer doesn't support a Flanterm terminal.

pub const FlantermFbRotation = enum(u64) {
    rotate_0 = 0,
    rotate_90 = 1,
    rotate_180 = 2,
    rotate_270 = 3,
    _,
};

pub const FlantermFbInitParams = extern struct {
    /// Pre-rendered background canvas buffer (32-bit pixels, same format as
    /// the associated framebuffer, at the framebuffer's width/height), or
    /// null if no wallpaper is configured.
    canvas: LiminePtr(?[*]u32),
    canvas_size: u64,
    ansi_colours: [8]u32,
    ansi_bright_colours: [8]u32,
    default_bg: u32,
    default_fg: u32,
    default_bg_bright: u32,
    default_fg_bright: u32,
    /// VGA-style font bitmap data, 256 glyphs, `font_width * font_height *
    /// 256 / 8` bytes.
    font: LiminePtr(*anyopaque),
    font_width: u64,
    font_height: u64,
    font_spacing: u64,
    font_scale_x: u64,
    font_scale_y: u64,
    margin: u64,
    rotation: FlantermFbRotation,

    /// Helper function to retrieve the canvas buffer as a slice of pixels.
    /// Returns null if no wallpaper is configured.
    pub fn getCanvas(self: @This()) ?[]u32 {
        if (self.canvas_size == 0 or self.canvas == null) {
            return null;
        }
        return self.canvas.?[0 .. self.canvas_size / @sizeOf(u32)];
    }
};

pub const FlantermFbInitParamsResponse = extern struct {
    revision: u64,
    entry_count: u64,
    entries: LiminePtr(?[*]*FlantermFbInitParams),

    /// Helper function to retrieve a slice of the entries array.
    /// This function will return null if the entry count is 0 or if
    /// the entries pointer is null.
    pub fn getEntries(self: @This()) []*FlantermFbInitParams {
        if (self.entry_count == 0 or self.entries == null) {
            return &.{};
        }
        return self.entries.?[0..self.entry_count];
    }
};

pub const FlantermFbInitParamsRequest = extern struct {
    id: [4]u64 = id(0x3259399fe7c5f126, 0xe01c1c8c5db9d1a9),
    revision: u64 = 0,
    response: LiminePtr(?*FlantermFbInitParamsResponse) = init_pointer,
};

comptime {
    if (protocol_revision > 6) {
        @compileError("Limine API revision must be 6 or lower");
    }

    std.testing.refAllDeclsRecursive(@This());
}
