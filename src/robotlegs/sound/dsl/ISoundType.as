package robotlegs.sound.dsl
{
    public interface ISoundType
    {
        function shot(volume:Number = 1, pan:Number = 0): ISoundListener;
        function loop(loops: int = 1, volume:Number = 1, pan:Number = 0): ISoundListener;
        function endlessLoop(volume:Number = 1, pan:Number = 0): ISoundListener;
    }
}