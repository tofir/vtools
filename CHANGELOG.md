# ChangeLog

## v 1.0.2

**Bug fixes**
* permissions fixed for created directories

## v 1.0.1

**Improvements:**
* *Handler* renamed to *Hook*
* path generator now automated

## v 0.1.1

**Improvements:**
* extconf.rb added to define external dependencies (ffmpeg & ffmpegthumnailer)
* all Errors now extend VTools::Error class
* CONFIG[:video_storage] and CONFIG[:thumb_storage] are not replaced with callback but prepended to the beginning of the callback-generated path

**Bug fixes:**
* fixed error when ffmpeg 0.8.7 could not take float values as resolution
* fixed parser for thumbnailer predefined set

## v 0.0.3 - Initial stable version