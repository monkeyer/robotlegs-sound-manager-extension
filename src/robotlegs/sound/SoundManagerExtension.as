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
package robotlegs.sound
{
    import org.swiftsuspenders.Injector;
    
    import robotlegs.bender.extensions.contextView.ContextView;
    import robotlegs.bender.framework.api.IContext;
    import robotlegs.bender.framework.api.IExtension;
    import robotlegs.bender.framework.api.ILogger;
    import robotlegs.sound.api.ISoundManager;
    import robotlegs.sound.impl.SoundManager;
    
    
    /**
     *
     * @author suspendmode@gmail.com
     *
     */
    public class SoundManagerExtension implements IExtension
    {
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        
        private var log: ILogger;
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        
        private var injector: Injector;
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        
        public function extend(context:IContext):void
        {
            injector = context.injector;
            
            log = context.getLogger(this);
            
            context.beforeInitializing(beforeInitializing);
            
            context.injector.map(ISoundManager).toSingleton(SoundManager);
        }
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        
        private function beforeInitializing():void
        {            
            if (!injector.hasMapping(ContextView)) {
                if (log)
                {
                    log.error("A ContextView must be installed if you install the SoundManagerExtension.");
                }
            }
        }
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        
        [PreDestroy]
        public function dispose(): void {            
            log = null;
            injector = null;            
        }
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    }
}
