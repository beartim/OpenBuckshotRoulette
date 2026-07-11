# Error analysis

The supplied build reached a successful Godot export. The generated PBX project
passed syntax validation, and the script then aborted because it found four
stale MoltenVK records in the stock Xcode project skeleton.

Those records are removed before Xcode reads the project. The supplied PBX file
contained no other Vulkan or MoltenVK linker setting.
