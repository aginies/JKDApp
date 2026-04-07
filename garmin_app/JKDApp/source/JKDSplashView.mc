import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Timer;
import Toybox.Math;

class JKDSplashView extends WatchUi.View {
    private var _timer;
    private var _ticks = 0;
    private var _maxTicks = 20; // 2 seconds at 100ms per tick

    function initialize() {
        View.initialize();
        _timer = new Timer.Timer();
    }

    function onShow() {
        _timer.start(method(:onAnimate), 100, true);
    }

    function onHide() {
        _timer.stop();
    }

    function onAnimate() {
        _ticks++;
        if (_ticks >= _maxTicks) {
            _timer.stop();
            goToMenu();
        }
        WatchUi.requestUpdate();
    }

    function goToMenu() {
        var seriesList = JKDSeries.getSeries();
        var delegate = new JKDAppMenuDelegate();
        var menuView;

        if (WatchUi has :CustomMenu) {
            var title = new WatchUi.Text({
                :text=>"JKD Training",
                :color=>Graphics.COLOR_WHITE,
                :font=>Graphics.FONT_TINY,
                :locX=>WatchUi.LAYOUT_HALIGN_CENTER,
                :locY=>20
            });
            menuView = new WatchUi.CustomMenu(45, Graphics.COLOR_BLACK, {:title=>title});
            for (var i = 0; i < seriesList.size(); i++) {
                menuView.addItem(new JKDSeriesItem(i, seriesList[i].title, seriesList[i].combos.size()));
            }
            menuView.addItem(new JKDSettingsItem(:item_settings, "Settings"));
        } else {
            menuView = new WatchUi.Menu2({:title=>"JKD Training"});
            for (var i = 0; i < seriesList.size(); i++) {
                menuView.addItem(new WatchUi.MenuItem(seriesList[i].title, seriesList[i].combos.size().toString() + " moves", i, null));
            }
            menuView.addItem(new WatchUi.MenuItem("Settings", null, :item_settings, null));
        }
        WatchUi.switchToView(menuView, delegate, WatchUi.SLIDE_LEFT);
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;
        var progress = _ticks.toFloat() / _maxTicks.toFloat();

        // 1. Draw-In Progress Ring
        var radius = (dc.getWidth() < dc.getHeight() ? dc.getWidth() : dc.getHeight()) / 2 - 10;
        dc.setPenWidth(4);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(centerX, centerY, radius);
        
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        var sweepAngle = - (progress * 360);
        dc.drawArc(centerX, centerY, radius, Graphics.ARC_CLOCKWISE, 90, 90 + sweepAngle);
        dc.setPenWidth(1);

        // 2. Center Logo
        var icon = WatchUi.loadResource(Rez.Drawables.JKDIcon);
        if (icon != null) {
            var iconWidth = icon.getWidth();
            var iconHeight = icon.getHeight();

            if (dc has :drawBitmap2) {
                var targetWidth = (dc.getWidth() * 0.8).toNumber();
                var targetHeight = (dc.getHeight() * 0.8).toNumber();
                var x = (dc.getWidth() - targetWidth) / 2;
                var y = (dc.getHeight() - targetHeight) / 2;
                dc.drawBitmap2(x, y, icon, {
                    :destWidth => targetWidth,
                    :destHeight => targetHeight
                });
            } else {
                dc.drawBitmap((dc.getWidth() - iconWidth) / 2, (dc.getHeight() - iconHeight) / 2, icon);
            }
        }

        // 3. Sliding Title
        var textY = centerY + (dc.getHeight() * 0.25);
        // Slide up slightly as it loads
        var slideOffset = (1.0 - progress) * 20;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, textY + slideOffset, Graphics.FONT_XTINY, "JEET KUNE DO", Graphics.TEXT_JUSTIFY_CENTER);
    }
}
