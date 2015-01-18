# Touch To Record Video
My barebones prototype of a feature similar to Vine's / Instagram's touch to record video. This will allow you to record short clips on touch down, pause upon release, and automatically stitch them all together when complete.

# How to Use
Set `maximumTimeLimit` and run the app. It was written programmatically based on `self.view.frame.size.width` so it should build for any iPhone. If you don't want square videos, simply modify `previewLayer.frame` and don't run `cropVideo:`

# Key Learnings and Decisions
- `AVCaptureMovieFileOutput` is kind of slow, it takes a few ms before it actually begins recording
- Thus, animation of the progress bar is an estimate independent of actual recording progress. I did this for UX reasons, allowing the app to feel more responsive on touch rather than waiting on `[MovieFileOutput isRecording]` and `[MovieFileOutput recordedDuration]`
- Because `AVCaptureMovieFileOutput` is slow, sometimes touches that last less than 0.0500 seconds will not actually record anything. `[MovieFileOutput stopRecording]` will get called before recording begins. This is bad UX compared to Vine, so perhaps a hack forcing a minimum record duration would be wise. (I haven't written that).
- As a result, videos with many touches will exceed your `maximumTimeLimit`, but otherwise its roughly accurate.

###Helpful sources I used:  
http://www.netwalk.be/article/record-square-video-ios  
http://www.raywenderlich.com/13418/how-to-play-record-edit-videos-in-ios  
Apologies for improper citations if any.
