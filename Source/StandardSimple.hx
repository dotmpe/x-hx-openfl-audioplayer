package;

import openfl.display.Sprite;
import openfl.errors.Error;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.ProgressEvent;
import openfl.media.Sound;
import openfl.media.SoundChannel;
import openfl.net.URLRequest;

class StandardSimple extends Sprite {
    private var sound:Sound;
    private var channel:SoundChannel;

    public function new() {
        super();

        sound = new Sound();
        sound.addEventListener(Event.COMPLETE, onSoundLoadComplete);
        sound.addEventListener(IOErrorEvent.IO_ERROR, onSoundIOError);

        var req:URLRequest;
        req = new URLRequest("assets/aqua.ogg");

        // WAVE works, but make sure its not using IEEE Float.
        //req = new URLRequest("assets/hymn_to_aurora.wav");

        // Cannot get mp3 to work.
        //req = new URLRequest("assets/simple.mp3");
        //req = new URLRequest("assets/standard.mp3");
        //req = new URLRequest("assets/test.mp3");
        //req = new URLRequest("assets/hymn_to_aurora_clean.mp3");
        //req = new URLRequest("assets/hymn_to_aurora.mp3");

        sound.load(req);
    }

    private function onSoundLoadComplete(event:Event):Void
    {
        var localSound:Sound = cast(event.target, Sound);
        trace("Sound length: " + localSound.length + " ms");
        trace("Sound bytes: " + localSound.bytesTotal);
        try {
          channel = localSound.play();
          if (channel == null) {
            trace("SoundChannel is null, playback failed.");
          } else {
            trace("Playback started successfully.");
          }
        } catch (e:Error) {
          trace("Playback error: " + e.message + " (ID: " + e.errorID + ")");
        }
    }

    private function onLoadProgress(event:ProgressEvent):Void
    {
        var loadedPct = Math.round(100 * (event.bytesLoaded / event.bytesTotal));
        trace("The sound is " + loadedPct + "% loaded.");
    }

    private function onSoundComplete(event:Event):Void {
        trace("Playback completed.");
    }

    private function onSoundIOError(event:IOErrorEvent):Void
    {
        trace("Error loading audio: " + event.toString());
    }
}
