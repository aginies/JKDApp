import Toybox.WatchUi;
import Toybox.Graphics;

class JKDMenu extends WatchUi.Menu2 {
    function initialize(options) {
        Menu2.initialize(options);
    }

    function onUpdate(dc) {
        Menu2.onUpdate(dc);
        
        if (dc has :drawBitmap2) {
            var icon = WatchUi.loadResource(Rez.Drawables.JKDIcon);
            if (icon != null) {
                var screenWidth = dc.getWidth();
                var miniSize = 35; 
                var x = (screenWidth - miniSize) / 2;
                var y = 50; // Positioned below the title
                
                dc.drawBitmap2(x, y, icon, {
                    :destWidth => miniSize,
                    :destHeight => miniSize
                });
            }
        }
    }
}
