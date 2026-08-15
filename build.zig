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

pub fn build(b: *std.Build) void {
    const revision = b.option(usize, "revision", "Protocol Revision") orelse 6;
    const no_pointers = b.option(bool, "no_pointers", "Disable pointers") orelse false;

    const options = b.addOptions();
    options.addOption(usize, "revision", revision);
    options.addOption(bool, "no_pointers", no_pointers);

    const module = b.addModule("limine", .{
        .root_source_file = b.path("src/root.zig"),
    });
    module.addImport("options", options.createModule());
}
