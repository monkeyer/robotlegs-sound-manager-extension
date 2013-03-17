/**
 *
 * Copyright 2012(C) by Piotr Kucharski.
 * email: suspendmode@gmail.com
 * mobile: +48 791 630 277
 *
 * All rights reserved. Any use, copying, modification, distribution and selling of this software and it's documentation
 * for any purposes without authors' written permission is hereby prohibited.
 *
 */
package robotlegs.sound.impl
{
	import com.greensock.TweenLite;

	import flash.events.Event;
	import flash.media.SoundTransform;
	import flash.utils.clearInterval;
	import flash.utils.setTimeout;

	import br.com.stimuli.loading.BulkLoader;

	import robotlegs.bender.extensions.contextView.ContextView;
	import robotlegs.bender.framework.api.ILogger;
	import robotlegs.bender.framework.impl.UID;
	import robotlegs.sound.api.ISoundManager;
	import robotlegs.sound.dsl.ISoundType;

	/**
	 *
	 * @author suspendmode@gmail.com
	 *
	 */
	public class SoundManager implements ISoundManager
	{

		[Inject(optional="true")]
		/**
		 *
		 */
		public var log:ILogger;

		[Inject]
		/**
		 *
		 */
		public var loader:BulkLoader;

		[Inject]
		/**
		 *
		 */
		public var contextView:ContextView;

		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		/**
		 *
		 */
		public static const UNLIMITED_LOOPS:int=-1;

		/**
		 *
		 */
		public const activeSounds:Vector.<ActiveSound>=new Vector.<ActiveSound>();

		/**
		 *
		 */
		public const playQueue:Vector.<ActiveSound>=new Vector.<ActiveSound>();

		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		[PostConstruct]
		public function initialize():void
		{
			var autoMute:Boolean=true;

			CONFIG::debug
			{
				autoMute=false;
			}
			contextView.view.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			contextView.view.stage.addEventListener(Event.ACTIVATE, onActivate);
			contextView.view.stage.addEventListener(Event.DEACTIVATE, onDeactivate);
		}

		[PreDestroy]
		public function dispose():void
		{
			contextView.view.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			contextView.view.stage.removeEventListener(Event.ACTIVATE, onActivate);
			contextView.view.stage.removeEventListener(Event.DEACTIVATE, onDeactivate);

			removeAll();
		}

		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////        

		private function onDeactivate(event:Event):void
		{
			//mute();
		}

		private function onActivate(event:Event):void
		{
			//unmute();
		}

		private function onEnterFrame(event:Event):void
		{
			while (playQueue.length)
			{
				playSound(playQueue.shift());
			}
		}

		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		public function play(soundID:String, id:String=null, fadeInTime:Number=0, delayTime:Number=0, startTime:Number=0):ISoundType
		{
			if (!id)
			{
				id=UID.create();
			}
			var activeSound:ActiveSound=new ActiveSound();
			activeSound.id=id;
			activeSound.sound=loader.getSound(soundID);
			activeSound.soundID=soundID;
			activeSound.id=id;
			activeSound.fadeInTime=fadeInTime;
			activeSound.delayTime=delayTime;
			activeSound.startTime=startTime;
			add(activeSound);
			playQueue.push(activeSound);
			return activeSound;
		}

		private function add(activeSound:ActiveSound):void
		{
            if (log) {
                log.debug("add sound {0}", [activeSound]);
            }
			activeSounds.push(activeSound);
		}

		private function remove(activeSound:ActiveSound):void
		{
            if (log) {
                log.debug("remove sound {0}", [activeSound]);
            }
			var index:int=activeSounds.indexOf(activeSound);
			activeSounds.splice(index, 1);
		}

		private function removeAll():void
		{
            if (activeSounds.length && log) {
                log.debug("remove all sounds {0}", [activeSounds]);
            }
			while (activeSounds.length)
			{
				remove(activeSounds.shift());
			}
		}

		public function stopByID(id:String, soundID:String, fadeOutTime:Number=0):void
		{
            if (log) {
                log.debug("stopByID id:{0} soundID:{1}, fadeOutTime:{2}", [id, soundID, fadeOutTime]);
            }
			var activeSound:ActiveSound=getByID(id, soundID);
			activeSound.fadeOutTime=fadeOutTime;
			stopSound(activeSound);
		}

		public function stopAll(soundID:String, fadeOutTime:Number=0):void
		{
            if (log) {
                log.debug("stopAll soundID:{0}, fadeOutTime:{1}", [soundID, fadeOutTime]);
            }
			var list:Vector.<ActiveSound>=getAll(soundID);
			for each (var activeSound:ActiveSound in list)
			{
				stopSound(activeSound);
			}
		}

		public function getByID(id:String, soundID:String):ActiveSound
		{            
			for each (var activeSound:ActiveSound in activeSounds)
			{
				if (activeSound.id == id && activeSound.soundID == soundID)
				{
					return activeSound;
				}
			}
			if (log)
			{
				log.error("no active sounds with id:{0}, soundID:{1} found.", [id, soundID]);
			}
			return null;
		}

		public function getAll(soundID:String):Vector.<ActiveSound>
		{
			var list:Vector.<ActiveSound>=new Vector.<ActiveSound>();
			for each (var activeSound:ActiveSound in activeSounds)
			{
				if (activeSound.soundID == soundID)
				{
					list.push(activeSound);
				}
			}
			return list;
		}

		private function playSound(activeSound:ActiveSound):void
		{
			if (activeSound.delayTime == 0)
			{
                if (log) {
                    log.debug("playSound:{0}", [activeSound]);
                }                
				playSoundInternal(activeSound);
			}
			else
			{
                if (log) {
                    log.debug("playSound:{0} with delay {1}", [activeSound, activeSound.delayTime]);
                }
				activeSound.delayTimeoutID=setTimeout(playSoundInternal, activeSound.delayTime, activeSound);
			}
		}

		private function playSoundInternal(activeSound:ActiveSound):void
		{
            if (log) {
                log.debug("playSoundInternal:{0}", [activeSound]);
            }
			var transform:SoundTransform=new SoundTransform(activeSound.volume, activeSound.pan);
            
			var onSoundComplete:Function=function(event:Event):void
			{
                if (log) {
                    log.debug("onSoundComplete:{0}", [activeSound]);
                }
				activeSound.soundChannel.removeEventListener(Event.SOUND_COMPLETE, onSoundComplete);
				if (activeSound.loops == ActiveSound.ENDLESS_LOOP)
				{
                    if (log) {
                        log.debug("looping endless loop:{0}", [activeSound]);
                    }
					playSoundInternal(activeSound);
				}
				else
				{
					stopSound(activeSound);
				}
			}
            
            if (activeSound.fadeInTime > 0)
            {
                transform.volume = 0;
            }
            activeSound.soundChannel=activeSound.sound.play(activeSound.startTime, activeSound.loops, transform);
            activeSound.soundChannel.addEventListener(Event.SOUND_COMPLETE, onSoundComplete);            
            
			if (activeSound.fadeInTime > 0)
			{
				var onFadeInComplete:Function=function():void
				{
                    if (log) {
                        log.debug("sound {0} faded in", [activeSound]);
                    }
                    activeSound.fadeTween = null;
				}
                if (log) {
                    log.debug("fading in {0} sound:{1}", [activeSound.fadeInTime, activeSound]);
                }
				activeSound.fadeTween=TweenLite.fromTo(activeSound, activeSound.fadeInTime, {volume:0}, {volume: activeSound.volume, onComplete: onFadeInComplete});                
			}             
		}

		private function stopSound(activeSound:ActiveSound):void
		{
            if (log) {
                log.debug("stopSound {0}", [activeSound]);
            }
			if (activeSound.delayTimeoutID != -1)
			{
                if (log) {
                    log.debug("clearInterval {0} for {1}", [activeSound.delayTimeoutID, activeSound]);
                }
				clearInterval(activeSound.delayTimeoutID);
				activeSound.delayTimeoutID=-1;
			}
			if (activeSound.fadeTween)
			{
                if (log) {
                    log.debug("kill fade tween {0} for {1}", [activeSound.fadeTween, activeSound]);
                }
				activeSound.fadeTween.kill();
				activeSound.fadeTween=null;
			}           
			if (activeSound.fadeOutTime == 0)
			{
                if (log) {
                    log.debug("stopping sound {0}", [activeSound]);
                }
                if (activeSound.soundChannel) {
				    activeSound.soundChannel.stop();
                    activeSound.soundChannel = null;
                }                
                remove(activeSound);
			}
			else
			{
                if (log) {
                    log.debug("fadeing out {0} sound:{1}", [activeSound.fadeOutTime, activeSound]);
                }
				var onFadeOutComplete:Function=function():void
				{
                    if (log) {
                        log.debug("sound {0} faded out ", [activeSound]);
                    }
					activeSound.fadeTween=null;
					remove(activeSound);
				}
				activeSound.fadeTween=TweenLite.to(activeSound, activeSound.fadeOutTime, {volume: 0, onComplete: onFadeOutComplete});
			}
		}

		private function pauseSound(activeSound:ActiveSound):void
		{

		}

		private function resumeSound(activeSound:ActiveSound):void
		{

		}

		private function pauseAll():void
		{

		}

		private function resumeAll():void
		{

		}

	/*public function getSound(url:String, context:SoundLoaderContext=null):Sound
	{
		if (url in sounds)
		{
			return sounds[url];
		}
		else
		{
			var sound:Sound=new Sound(new URLRequest(url), context);
			sounds[url]=sound;
			return sound;
		}
	}

	public function removeAllSounds():void
	{
		for (var url:String in sounds)
		{
			removeSound(url);
		}
	}

	public function removeSound(url:String):Sound
	{
		var sound:Sound=sounds[url];
		sound.close();
		delete sounds[url];
		return sound;
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	public function loadAndPlay(url:String, context:SoundLoaderContext=null, fadeIn:Boolean=false, startTime:Number=0, loops:int=0, volume:Number=1, pan:Number=0, muted:Boolean=false):ActiveSound
	{
		var sound:Sound=getSound(url, context);
		var info:ActiveSound=play(sound, UID.create(sound), null, fadeIn, startTime, loops, volume, pan, muted);
		return info;
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	public function playLoop(sound:Sound, soundID:String, channelID:String=null, fadeIn:Boolean=false, startTime:Number=0, volume:Number=1, pan:Number=0, muted:Boolean=false):ActiveSound
	{
		var info:ActiveSound=play(sound, UID.create(sound), null, fadeIn, startTime, SoundManager.UNLIMITED_LOOPS, volume, pan, muted);
		return info;
	}
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	public function play(sound:Sound, soundID:String, channelID:String=null, fadeIn:Boolean=false, startTime:Number=0, loops:int=0, volume:Number=1, pan:Number=0, muted:Boolean=false):ActiveSound
	{

		var oldInfo:ActiveSound=getSoundInfo(soundID, channelID);
		if (oldInfo)
		{
			stopSoundInfo(oldInfo);
		}

		var info:ActiveSound=new ActiveSound();

		info.id=soundID;
		info.channelID=channelID;

		info.loops=loops;
		info.startTime=startTime;

		info.volume=volume;
		info.muted=muted;
		info.pan=pan;

		info.sound=sound;

		playSoundInfo(info);

		addSoundInfo(info);

		return info;
	}

	private function stopSoundInfo(info:ActiveSound):void
	{

	}

	private function playSoundInfo(info:ActiveSound):void
	{
		var onSoundComplete:Function=function(event:Event):void
		{
			info.soundChannel.removeEventListener(Event.SOUND_COMPLETE, onSoundComplete);
			if (info.loops == UNLIMITED_LOOPS)
			{
				info.soundChannel=info.sound.play(info.startTime, info.loops, info.soundTransform);
				info.soundChannel.addEventListener(Event.SOUND_COMPLETE, onSoundComplete);
			}
			else if (info.loops > 0)
			{
				info.loops--;
				info.soundChannel=info.sound.play(info.startTime, info.loops, info.soundTransform);
				info.soundChannel.addEventListener(Event.SOUND_COMPLETE, onSoundComplete);
			}
			else
			{
				removeSoundInfo(info);
			}
		}

		info.soundChannel=info.sound.play(info.startTime, info.loops);

		if (!info.soundChannel)
		{
			throw new IllegalOperationError("no audion channels available");
		}

		info.soundChannel.addEventListener(Event.SOUND_COMPLETE, onSoundComplete);
		return info;
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	public function stop(soundID:String, channelID:String=null, fadeOut:Boolean=false):void
	{
		if (channelID)
		{

		}
		else
		{

		}

		var infos:Vector.<ActiveSound>=getSoundInfos(soundID, channelID);

		for each (var info:ActiveSound in infos)
		{
			var volumeFrom:Number=info.soundChannel.soundTransform.volume;
			function fadeAudio(e:Event):void
			{
				volumeFrom-=.05;
				if (volumeFrom <= 0)
				{
					volumeFrom=0;
					contextView.view.stage.removeEventListener(Event.ENTER_FRAME, fadeAudio);
					info.soundChannel.stop();

				}
				var transform:SoundTransform=new SoundTransform(volumeFrom, 0);
				info.soundChannel.soundTransform=transform;
			}

			contextView.view.stage.addEventListener(Event.ENTER_FRAME, fadeAudio);
			removeSoundInfo(info);
		}
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	public function setVolume(soundID:String, channelID:String, volume:Number):void
	{
		var info:ActiveSound=getSoundInfo(soundID, channelID);
		info.volume=volume;
	}

	public function setVolumeToAll(soundID:String, volume:Number):void
	{
		var infos:Vector.<ActiveSound>=getSoundInfos(soundID);
		for each (var info:ActiveSound in infos)
		{
			info.volume=volume;
		}
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


	public function setPan(soundID:String, channelID:String, pan:Number):void
	{
		var info:ActiveSound=getSoundInfo(soundID, channelID);
		info.volume=pan;
	}

	public function setPanToAll(soundID:String, pan:Number):void
	{
		var infos:Vector.<ActiveSound>=getSoundInfos(soundID);
		for each (var info:ActiveSound in infos)
		{
			info.volume=pan;
		}
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


	public function setMuted(soundID:String, channelID:String, muted:Boolean):void
	{
		var info:ActiveSound=getSoundInfo(soundID, channelID);
		info.muted=muted;
	}

	public function setMutedToAll(soundID:String, muted:Number):void
	{
		var infos:Vector.<ActiveSound>=getSoundInfos(soundID);
		for each (var info:ActiveSound in infos)
		{
			info.muted=muted;
		}
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	public function getPan(soundID:String, channelID:String):Number
	{
		var info:ActiveSound=getSoundInfo(soundID, channelID);
		return info.pan;
	}

	public function getVolume(soundID:String, channelID:String):Number
	{
		var info:ActiveSound=getSoundInfo(soundID, channelID);
		return info.volume;
	}

	public function isMuted(soundID:String, channelID:String):Boolean
	{
		var info:ActiveSound=getSoundInfo(soundID, channelID);
		return info.muted;
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	private function getSoundInfos(soundID:String):Vector.<ActiveSound>
	{
		var list:Vector.<ActiveSound>=new Vector.<ActiveSound>();
		for each (var info:ActiveSound in activeSounds)
		{
			if (info.id == soundID)
			{
				list.push(info);
			}
		}
		return list;
	}

	private function getSoundInfo(soundID:String, channelID:String):ActiveSound
	{
		for each (var info:ActiveSound in activeSounds)
		{
			if (info.id == soundID && info.channelID == channelID)
			{
				return info;
			}
		}

		return null;
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	private function addSoundInfo(info:ActiveSound):void
	{
		activeSounds.push(info);
	}

	private function removeSoundInfo(info:ActiveSound):void
	{
		var index:int=activeSounds.indexOf(info);
		activeSounds.splice(index, 1);
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	public const _activeSounds:Vector.<ActiveSound>=new Vector.<ActiveSound>();

	public function get activeSounds():Vector.<ActiveSound>
	{
		return _activeSounds;
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	private var _volume:Number=1;

	public function get volume():Number
	{
		return _volume;
	}

	public function set volume(value:Number):void
	{
		if (_volume == value)
			return;
		_volume=value;
		updateGlobalSoundTransform();
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	private var _pan:Number=0;

	public function get pan():Number
	{
		return _pan;
	}

	public function set pan(value:Number):void
	{
		if (_pan == value)
			return;
		_pan=value;
		updateGlobalSoundTransform();
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	private var _muted:Boolean=false;

	public function get muted():Boolean
	{
		return _muted;
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	public function mute():void
	{
		_muted=true;
		updateGlobalSoundTransform();
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	public function unmute():void
	{
		_muted=false;
		updateGlobalSoundTransform();
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	private function updateGlobalSoundTransform():void
	{
		var transform:SoundTransform=SoundMixer.soundTransform;
		transform.volume=muted ? 0 : volume;
		transform.pan=pan;
	}*/

		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	}
}
