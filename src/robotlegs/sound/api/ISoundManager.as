package robotlegs.sound.api
{
    import robotlegs.sound.dsl.ISoundType;
    import robotlegs.sound.impl.ActiveSound;
	

	public interface ISoundManager
	{
        function play(soundID: String, id: String = null, fadeInTime: Number = 0, delayTime: Number = 0, startTime: Number = 0): ISoundType;

        function stopByID(id: String, soundID: String, fadeOutTime: Number = 0): void;
        
        function stopAll(soundID: String, fadeOutTime: Number = 0): void;
        
        function getByID(id: String, soundID: String): ActiveSound;
        
        function getAll(soundID: String): Vector.<ActiveSound>;
        
	/*function getSound(url:String, context:SoundLoaderContext=null):Sound;

	function removeSound(url:String):Sound;

	function removeAllSounds():void;

	function play(sound:Sound, soundID:String, channelID:String=null, startTime:Number=0, loops:int=0, volume:Number=1, pan:Number=0, muted:Boolean=false):ActiveSound;

	function stop(soundID:String, channelID:String=null):void;

	function setVolume(soundID:String, channelID:String=null, volume:Number):void;

	function setPan(soundID:String, channelID:String=null, pan:Number):void;

	function getVolume(soundID:String, channelID:String=null):Number;

	function getPan(soundID:String, channelID:String=null):Number;

	function isMuted(soundID:String, channelID:String=null):Boolean;

	function get activeSounds():Vector.<ActiveSound>;

	function set volume(value:Number):void;
	function get volume():Number;

	function set pan(value:Number):void;
	function get pan():Number;

	function mute():void;
	function unmute():void;

	function get muted():Boolean;*/
	}
}
