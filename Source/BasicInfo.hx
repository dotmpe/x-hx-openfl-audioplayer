package;

import openfl.Assets;
import openfl.display.Sprite;
import openfl.errors.Error;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.media.SoundChannel;
import openfl.media.SoundTransform;
import openfl.net.URLRequest;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.ui.Keyboard;
import haxe.Json;

typedef PlaylistTrack = {
    url:String,
    title:String
}

class BasicInfo extends Sprite {
    private var sound:Sound;
    private var channel:SoundChannel;
    private var titleLabel:TextField;
    private var progressBar:Sprite;
    private var progressText:TextField;
    private var playlist:Array<PlaylistTrack>;
    private var currentTrackIndex:Int = -1;
    private var currentPosition:Float = 0;
    private var isPaused:Bool = false;
    private var isMuted:Bool = false;
    private var soundTransform:SoundTransform;

    public function new() {
        super();

        //playlist = loadPlaylist();
		    playlist = randomizeArray(loadPlaylist());
        if (playlist.length == 0) {
            trace("Error: Empty or invalid playlist");
            return;
        }

        var font = Assets.getFont("topaz");
        var fontName = font != null ? font.fontName : "_sans";
        trace("Using font: " + fontName);
        var textFormat = new TextFormat(fontName, 18, 0xEEEEEC);
        var textFormat2 = new TextFormat(fontName, 14, 0x8AE234);

        // Title text
        titleLabel = new TextField();
        titleLabel.defaultTextFormat = textFormat;
        titleLabel.text = "< load >";
        titleLabel.selectable = false;
        addChild(titleLabel);

        // Progress bar
        progressBar = new Sprite();
        addChild(progressBar);

        // Percentage text (aligned with progress bar)
        progressText = new TextField();
        progressText.defaultTextFormat = textFormat2;
        progressText.text = "0%";
        progressText.selectable = false;
        addChild(progressText);

	      // Initialize single sound or playlist
		    //= Assets.getText("assets/" + glFragmentShaders[currentIndex] + ".frag");

        // Initialize sound
        sound = new Sound();
        sound.addEventListener(Event.COMPLETE, onSoundLoadComplete);
        sound.addEventListener(IOErrorEvent.IO_ERROR, onSoundIOError);
        playNextTrack();

        // Layout UI initially
        layoutUI();

        // Register event listeners
        addEventListener(Event.ENTER_FRAME, onEnterFrame);
        stage.addEventListener(Event.RESIZE, onResize);
        stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);

        // Ensure initial resize (for some platforms)
        stage.dispatchEvent(new Event(Event.RESIZE));
    }

    private function onKeyDown(event:KeyboardEvent):Void {
        // XXX: could check event.shiftKey if wanted...
        switch (event.keyCode) {
            case Keyboard.ESCAPE:
                stopTrack();
            case Keyboard.COMMA:
                playPreviousTrack();
            case Keyboard.PERIOD:
                playNextTrack();
            case Keyboard.UP:
                seek(20);
            case Keyboard.DOWN:
                seek(-20);
            case Keyboard.LEFT:
                seek(-5);
            case Keyboard.RIGHT:
                seek(5);
            case Keyboard.SPACE:
                togglePause();
            //case Keyboard.ENTER: FIXME: triggers segfault
            //    toggleMute();
        }
    }

    private function playPreviousTrack():Void {
        currentTrackIndex--;
        if (currentTrackIndex < 0) {
            currentTrackIndex = playlist.length - 1; // Loop to last track
        }
        playTrack(currentTrackIndex);
    }

    private function playNextTrack():Void {
        currentTrackIndex++;
        if (currentTrackIndex >= playlist.length) {
            currentTrackIndex = 0; // Loop to first track
        }
        playTrack(currentTrackIndex);
    }

    private function getProgress():Float {
        if (channel != null && sound != null && sound.length > 0) {
            return Math.min(1.0, Math.max(0.0, currentPosition / sound.length));
        }
        return 0;
    }

    private function layoutUI():Void {
        // Get current window dimensions
        var windowWidth:Float = stage.stageWidth;
        var windowHeight:Float = stage.stageHeight;
        var marginX:Float = 20; // Left and right margin
        var progressBarWidth:Float = windowWidth - 2 * marginX;
        var progressBarHeight:Float = 20;
        var titleHeight:Float = 20;
        var spacing:Float = 10; // Space between title, bar, and text
        var totalHeight:Float = titleHeight + spacing + progressBarHeight; // ~50 pixels
        var yOffset:Float = (windowHeight - totalHeight) / 2;

        // Update title text
        titleLabel.x = marginX; //
        titleLabel.y = marginX; //
        titleLabel.width = progressBarWidth;
        titleLabel.y = yOffset;

        // Update progress bar
        progressBar.x = marginX;
        progressBar.y = yOffset + titleHeight + spacing;
        updateProgressBar(getProgress()); // Redraw with new width

        // Update percentage text
        progressText.x = marginX + (progressBarWidth/2);
        progressText.y = yOffset + titleHeight + spacing;
        progressText.width = 50;
    }

    private function loadPlaylist():Array<PlaylistTrack> {
        var playlistData = Assets.getText("assets/playlist.json");
        if (playlistData == null) {
            trace("Error: Could not load playlist.json");
            return [];
        }
        try {
            return Json.parse(playlistData);
        } catch (e:Dynamic) {
            trace("Error parsing JSON: " + e);
            return [];
        }
    }

    private function onEnterFrame(event:Event):Void {
        if (channel != null && sound != null && sound.length > 0 && !isPaused) {
            currentPosition = channel.position; // Update position
            var progress = currentPosition / sound.length;
            progress = Math.min(1.0, Math.max(0.0, progress));
            progressText.text = Math.round(progress * 100) + "%";
            updateProgressBar(progress);
        }
    }

    private function onSoundIOError(event:IOErrorEvent):Void {
        trace("Error loading: " + event.toString());
    }

    private function onResize(event:Event):Void {
        layoutUI(); // Re-layout UI on resize
    }

    private function onSoundComplete(event:Event):Void {
        trace("Playback completed: "+playlist[currentTrackIndex].url);
        progressText.text = "100%";
        updateProgressBar(1.0);
        playNextTrack();
    }

    private function onSoundLoadComplete(event:Event):Void {
        try {
            channel = sound.play(currentPosition);
            if (channel == null) {
                trace("SoundChannel is null, playback failed.");
            } else {
                trace("Playback started: "+playlist[currentTrackIndex].url);
                channel.addEventListener(Event.SOUND_COMPLETE, onSoundComplete);
            }
        } catch (e:Error) {
            trace("Playback error: " + e.message + " (ID: " + e.errorID + ")");
        }
    }

    private function stopTrack():Void {
        if (channel != null) {
            channel.stop();
            channel = null;
            sound = null;
        }
    }

    private function togglePause():Void {
        if (channel == null || sound == null) return;

        isPaused = !isPaused;
        if (isPaused) {
            currentPosition = channel.position;
            channel.stop();
        } else {
            channel = sound.play(currentPosition);
            if (channel != null) {
                channel.soundTransform = soundTransform;
                channel.addEventListener(Event.SOUND_COMPLETE, onSoundComplete);
            }
        }
    }

    //private function toggleMute():Void {
    //    if (channel == null) return;

    //    isMuted = !isMuted;
    //    soundTransform.volume = isMuted ? 0 : 1;
    //    channel.soundTransform = soundTransform;
    //}

    private function playTrack(index:Int):Void {
        if (channel != null) {
            channel.stop();
            channel = null;
        }
        if (sound != null) {
            sound = null;
        }

        var track = playlist[index];
        titleLabel.text = track.title;
        sound = new Sound();
        sound.addEventListener(Event.COMPLETE, onSoundLoadComplete);
        sound.addEventListener(IOErrorEvent.IO_ERROR, onSoundIOError);
        sound.load(new URLRequest(track.url));
        currentPosition = 0;
        isPaused = false;
    }

    private function randomizeArray<T>(array:Array<T>):Array<T>
    {
        var arrayCopy = array.copy();
        var randomArray = new Array<T>();

        while (arrayCopy.length > 0)
        {
          var randomIndex = Math.round(Math.random() * (arrayCopy.length - 1));
          randomArray.push(arrayCopy.splice(randomIndex, 1)[0]);
        }

        return randomArray;
    }

    private function seek(seconds:Float):Void {
        if (channel != null && sound != null && sound.length > 0) {
            var newPosition = currentPosition + seconds * 1000; // Convert to milliseconds
            newPosition = Math.max(0, Math.min(sound.length, newPosition)); // Clamp to track bounds
            channel.stop();
            channel = sound.play(newPosition);
            if (channel != null) {
                channel.addEventListener(Event.SOUND_COMPLETE, onSoundComplete);
                currentPosition = newPosition;
            }
        }
    }

    private function updateProgressBar(progress:Float):Void {
        var windowWidth:Float = stage.stageWidth;
        var marginX:Float = 20;
        var progressBarWidth:Float = windowWidth - 2 * marginX;
        var progressBarHeight:Float = 20;
    
        progressBar.graphics.clear();
        progressBar.graphics.beginFill(0x172E02); // Very dark green background
        progressBar.graphics.drawRect(0, 0, progressBarWidth, progressBarHeight);
        progressBar.graphics.endFill();
        progressBar.graphics.beginFill(0x4E9A06); // Tango Chameleon Dark (active)
        progressBar.graphics.drawRect(0, 0, progressBarWidth * progress, progressBarHeight);
        progressBar.graphics.endFill();        
    }
}
