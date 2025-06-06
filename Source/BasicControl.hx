package;

import openfl.Assets;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.MouseEvent;
import openfl.media.Sound;
import openfl.media.SoundChannel;
import openfl.net.URLRequest;
import openfl.text.TextField;
import openfl.text.TextFormat;

class BasicControl extends Sprite {
    private var sound:Sound;
    private var channel:SoundChannel;
    private var isPaused:Bool = false;
    private var titleLabel:TextField;
    private var pauseButton:TextField;

    public function new() {
        super();

        var font = Assets.getFont("topaz");
        var fontName = font != null ? font.fontName : "_sans";
        trace("Using font: " + fontName);
        var textFormat = new TextFormat(fontName, 14, 0x8AE234);

        // Title text
        titleLabel = new TextField();
        titleLabel.defaultTextFormat = textFormat;
        titleLabel.x = 20;
        titleLabel.y = 20;
        titleLabel.text = "Hymn to Aurora";
        titleLabel.selectable = false;
        addChild(titleLabel);

        // Title text
        var textFormat2 = new TextFormat(fontName, 14, 0x8AE234);
        textFormat2.leftMargin = 25;
        textFormat2.rightMargin = 45;
        pauseButton = new TextField();
        pauseButton.defaultTextFormat = textFormat2;
        pauseButton.text = "Pause";
        pauseButton.x = 20;
        pauseButton.y = 35;
        pauseButton.width = 100;
        pauseButton.height = 100;
        pauseButton.background = true;
        pauseButton.backgroundColor = 0x080808;
        pauseButton.selectable = false;
        pauseButton.border = true;
        pauseButton.borderColor = 0x172E02;
        pauseButton.addEventListener(MouseEvent.CLICK, onPauseClick);
        addChild(pauseButton);

        sound = new Sound();
        sound.addEventListener(Event.COMPLETE, onSoundLoadComplete);
        sound.addEventListener(IOErrorEvent.IO_ERROR, onSoundIOError);
        sound.load(new URLRequest("assets/hymn_to_aurora.ogg"));
    }

    private function onSoundLoadComplete(event:Event):Void {
        trace("The sound is 100% loaded.");
        channel = sound.play();
        if (channel == null) {
            trace("SoundChannel is null, playback failed.");
        }
    }

    private function onPauseClick(event:MouseEvent):Void {
        if (channel != null) {
            if (isPaused) {
                channel = sound.play(channel.position);
                pauseButton.text = "Pause";
                isPaused = false;
            } else {
                channel.stop();
                pauseButton.text = "Resume";
                isPaused = true;
            }
        }
    }

    private function onSoundIOError(event:IOErrorEvent):Void {
        trace("Error loading sound: " + event.toString());
    }
}
