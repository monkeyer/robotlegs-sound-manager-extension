package robotlegs.sound.dsl
{
    public interface ISoundListener
    {
        function onSoundComplete(callback: Function): void;
        
        function onComplete(callback: Function): void;
    }
}