class_name MobileDetector

## Returns true if the current platform is mobile (or touch-capable web).
## Checks both native mobile feature flag and touchscreen availability so it
## works for: compiled APK/IPA  AND  web-on-mobile-browser.
static func is_mobile() -> bool:
	if OS.has_feature("mobile"):
		return true
	if DisplayServer.is_touchscreen_available():
		return true
	return false
