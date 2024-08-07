package wotstat.widgets {

  import flash.display.Sprite;
  import flash.events.MouseEvent;
  import flash.geom.Rectangle;
  import wotstat.widgets.controls.Close;
  import wotstat.widgets.controls.Lock;
  import wotstat.widgets.controls.Resize;
  import wotstat.widgets.controls.ResizeControl;
  import flash.events.Event;
  import scaleform.clik.events.ResizeEvent;
  import wotstat.widgets.controls.HideShow;
  import wotstat.widgets.controls.Reload;
  import wotstat.widgets.controls.Close;
  import wotstat.widgets.controls.Button;
  import flash.geom.Point;
  import flash.utils.ByteArray;
  import flash.display.Loader;
  import flash.display.Graphics;
  import flash.display.Bitmap;
  import flash.display.PixelSnapping;
  import wotstat.widgets.common.MoveEvent;

  public class DraggableWidget extends Sprite {
    public static const REQUEST_RESIZE:String = "REQUEST_RESIZE";
    public static const REQUEST_RELOAD:String = "REQUEST_RELOAD";
    public static const REQUEST_CLOSE:String = "REQUEST_CLOSE";
    public static const MOVE_WIDGET:String = "MOVE_WIDGET";
    public static const LOCK_WIDGET:String = "LOCK_WIDGET";
    public static const UNLOCK_WIDGET:String = "UNLOCK_WIDGET";
    public static const HIDE_WIDGET:String = "HIDE_WIDGET";
    public static const SHOW_WIDGET:String = "SHOW_WIDGET";

    private const HANGAR_TOP_OFFSET:int = 0;
    private const HANGAR_BOTTOM_OFFSET:int = 90;
    private const HANGAR_HEADER_MINIFIED_HEIGHT:int = 35;

    private var _wid:int = 0;

    private var hideShowBtn:HideShow = new HideShow();
    private var lockBtn:Lock = new Lock(onLockButtonClick);
    private var resizeBtn:Resize = new Resize(onResizeButtonClick);
    private var reloadBtn:Reload = new Reload(onReloadButtonClick);
    private var closeBtn:Close = new Close(onCloseButtonClick);

    private var controlPanel:ControlsPanel = new ControlsPanel();
    private const resizeControl:ResizeControl = new ResizeControl(0, 0);

    // Target width by resize control in POINTS
    private var targetWidth:Number = -1;
    private var targetHeight:Number = -1;

    private var hideShowButtonDownPosition:Point = null;
    private var isDragging:Boolean = false;
    private var isContentHidden:Boolean = false;
    private var _isLocked:Boolean = false;

    // CONTENT == Browser Image in readl PIXELS
    private var contentWidth:Number = 0;
    private var contentHeight:Number = 0;
    private var content:Sprite = new Sprite();
    private var loader:Loader = new Loader();

    public var isInBattle:Boolean = false;

    public function get wid():int {
      return _wid;
    }

    public function get isLocked():Boolean {
      return _isLocked;
    }

    public function get isHidden():Boolean {
      return isContentHidden;
    }

    public function DraggableWidget(wid:int, width:int, height:int, x:int, y:int, isHidden:Boolean, isLocked:Boolean, isInBattle:Boolean) {
      super();
      _wid = wid;
      this.isInBattle = isInBattle;

      addChild(content);
      content.addChild(loader);

      controlPanel
        .addButton(hideShowBtn)
        .addButton(lockBtn)
        .addButton(resizeBtn)
        .addButton(reloadBtn)
        .addButton(closeBtn)
        .layout();

      addChild(controlPanel);
      controlPanel.y = -controlPanel.height - 3;
      hitArea = controlPanel;

      targetWidth = width / App.appScale;
      if (height > 0)
        targetHeight = height / App.appScale;

      this.x = x >= 0 ? x : (App.appWidth - targetWidth) / 2;
      this.y = y >= 0 ? y : (App.appHeight - height / App.appScale - 100) / 2;
      contentWidth = width;
      contentHeight = height;

      addChild(resizeControl);

      fixPosition();

      content.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
      App.instance.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
      App.instance.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
      App.instance.addEventListener(Event.RESIZE, onAppResize);
      resizeControl.addEventListener(ResizeControl.RESIZE_MOVE, onResizeControlChange);
      resizeControl.addEventListener(ResizeControl.RESIZE_END, onReziseControlEnd);
      loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);
      hideShowBtn.addEventListener(MouseEvent.MOUSE_DOWN, onHideShowButtonMouseDown);

      updateImageScale();

      setHidden(isHidden);
      setLocked(isLocked);
    }

    public function dispose():void {
      loader.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
      App.instance.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
      App.instance.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
      resizeControl.removeEventListener(ResizeControl.RESIZE_MOVE, onResizeControlChange);
      resizeControl.removeEventListener(ResizeControl.RESIZE_END, onReziseControlEnd);
      loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoaderComplete);
      hideShowBtn.removeEventListener(MouseEvent.MOUSE_DOWN, onHideShowButtonMouseDown);

      for each (var btn:Button in [hideShowBtn, lockBtn, resizeBtn, reloadBtn, closeBtn]) {
        btn.dispose();
      }

      loader.unload();
    }

    public function setFrame(width:uint, height:uint, data:ByteArray):void {

      if (width != targetWidth * App.appScale && !resizeControl.isResizing) {
        trace("[DW] Skip frame with width " + width + "!=" + targetWidth * App.appScale);
        return;
      }

      loader.unload();
      loader.loadBytes(data);

      contentWidth = width;
      contentHeight = height;

      updateImageScale();
      updateResizeControl();
    }

    public function setResizeMode(full:Boolean):void {
      trace("[DW] Set resize mode " + full);
      resizeControl.fullResize = full;
    }

    public function setControlsVisible(isVisible:Boolean):void {
      controlPanel.visible = isVisible;
      resizeControl.active = false;
    }

    public function onInterfaceScaleChanged(scale:Number):void {
      trace("[DW] Interface scale changed " + scale + "x" + App.appScale);
      updateImageScale();
      updateResizeControl();
      dispatchEvent(new ResizeEvent(REQUEST_RESIZE, targetWidth * App.appScale, targetHeight * App.appScale));
    }

    private function setHidden(value:Boolean):void {
      if (isContentHidden == value)
        return;

      isContentHidden = value;
      hideShowBtn.isShow = !value;
      content.visible = !value;

      if (resizeControl.active) {
        resizeControl.active = false;
      }

      updateButtonsVisibility();
    }

    private function setLocked(value:Boolean):void {
      if (_isLocked == value)
        return;

      _isLocked = value;

      if (resizeControl.active) {
        resizeControl.active = false;
      }

      content.mouseEnabled = !_isLocked;
      content.mouseChildren = !_isLocked;
      updateButtonsVisibility();
    }

    private function onLoaderComplete(event:Event):void {
      (loader.content as Bitmap).pixelSnapping = PixelSnapping.ALWAYS;
      (loader.content as Bitmap).smoothing = false;
    }

    private function getDraggingRectange(full:Boolean, battle:Boolean = false):Rectangle {
      if (full && !battle)
        return new Rectangle(
            0,
            HANGAR_TOP_OFFSET,
            App.appWidth - content.width,
            App.appHeight - content.height - HANGAR_TOP_OFFSET - HANGAR_BOTTOM_OFFSET
          );

      if (!full && !battle)
        return new Rectangle(
            0,
            HANGAR_TOP_OFFSET + HANGAR_HEADER_MINIFIED_HEIGHT + controlPanel.height + 2,
            App.appWidth - controlPanel.height,
            App.appHeight - controlPanel.height - HANGAR_TOP_OFFSET - HANGAR_HEADER_MINIFIED_HEIGHT - HANGAR_BOTTOM_OFFSET
          );

      if (full && battle)
        return new Rectangle(
            0,
            0,
            App.appWidth - content.width,
            App.appHeight - content.height
          );


      if (!full && battle)
        return new Rectangle(
            0,
            controlPanel.height + 2,
            App.appWidth - controlPanel.height,
            App.appHeight - controlPanel.height
          );

      return new Rectangle(0, 0, App.appWidth, App.appHeight);
    }

    private function onMouseDown(event:MouseEvent):void {
      if (isDragging)
        return;

      isDragging = true;
      startDrag(false, getDraggingRectange(!isHidden, isInBattle));
    }

    private function onMouseMove(event:MouseEvent):void {
      if (hideShowButtonDownPosition != null) {
        var dx:Number = event.stageX - hideShowButtonDownPosition.x;
        var dy:Number = event.stageY - hideShowButtonDownPosition.y;

        if (Math.sqrt(dx * dx + dy * dy) > 5 && isContentHidden && !_isLocked) {
          hideShowButtonDownPosition = null;
          isDragging = true;
          x += dx;
          y += dy;
          startDrag(false, getDraggingRectange(!isHidden, isInBattle));
        }
      }
    }

    private function onMouseUp(event:MouseEvent):void {

      if (hideShowButtonDownPosition != null) {
        hideShowButtonDownPosition = null;

        if (event.target == hideShowBtn) {
          onHideShowButtonClick();
        }
      }

      if (!isDragging)
        return;

      x = Math.round(x);
      y = Math.round(y);

      isDragging = false;
      stopDrag();
      dispatchEvent(new MoveEvent(MOVE_WIDGET, x, y));
    }

    private function onHideShowButtonMouseDown(event:MouseEvent):void {
      hideShowButtonDownPosition = new Point(event.stageX, event.stageY);
    }

    private function onHideShowButtonClick():void {
      setHidden(!isContentHidden);
      dispatchEvent(isContentHidden ? new Event(HIDE_WIDGET) : new Event(SHOW_WIDGET));
    }

    private function onResizeButtonClick(event:MouseEvent):void {
      resizeControl.active = !resizeControl.active;
    }

    private function onLockButtonClick(event:MouseEvent):void {
      setLocked(!_isLocked);
      dispatchEvent(_isLocked ? new Event(UNLOCK_WIDGET) : new Event(LOCK_WIDGET));
    }

    private function updateButtonsVisibility():void {
      for each (var value:Button in [resizeBtn, reloadBtn, closeBtn]) {
        value.visible = !isContentHidden && !_isLocked;
      }

      lockBtn.visible = !isContentHidden;
      controlPanel.layout();
    }

    private function onReloadButtonClick(event:MouseEvent):void {
      dispatchEvent(new Event(REQUEST_RELOAD));
    }

    private function onCloseButtonClick(event:MouseEvent):void {
      dispatchEvent(new Event(REQUEST_CLOSE));
    }

    private function onResizeControlChange(event:ResizeEvent):void {
      trace("[DW] Resize control changed " + event.scaleX + "x" + event.scaleY);
      targetWidth = event.scaleX;
      targetHeight = event.scaleY;
      updateImageScale();
      updateResizeControl();
    }

    private function onReziseControlEnd(event:Event):void {
      targetWidth = Math.round(targetWidth);
      targetHeight = Math.round(targetHeight);
      trace("[DW] Resize control end " + targetWidth + "x" + targetHeight);
      updateImageScale();

      resizeControl.contentWidth = targetWidth;
      resizeControl.contentHeight = targetHeight >= 0 ? targetHeight : targetWidth * contentHeight / contentWidth;

      dispatchEvent(new ResizeEvent(REQUEST_RESIZE, targetWidth * App.appScale, targetHeight * App.appScale));
    }

    private function fixPosition():void {
      x = Math.round(x);
      y = Math.round(y);

      var rect:Rectangle = getDraggingRectange(!isHidden, isInBattle);
      if (x < rect.x)
        x = rect.x;
      if (y < rect.y)
        y = rect.y;
      if (x > rect.width + rect.x)
        x = rect.width + rect.x;
      if (y > rect.height + rect.y)
        y = rect.height + rect.y;
    }

    private function onAppResize(event:Event):void {
      if (isDragging) {
        stopDrag();
        isDragging = false;
      }
      fixPosition();
    }

    private function updateImageScale():void {
      if (!resizeControl.fullResize) {
        var k:Number = targetWidth / contentWidth;
        content.scaleX = k;
        content.scaleY = k;
      }

      if (content.width != contentWidth / App.appScale || content.height != contentHeight / App.appScale) {
        var graphics:Graphics = content.graphics;
        graphics.clear();
        graphics.beginFill(0x000000, 0);
        graphics.drawRect(0, 0, contentWidth, contentHeight);
        graphics.endFill();
      }
    }

    private function updateResizeControl():void {
      resizeControl.contentWidth = contentWidth * content.scaleX;
      resizeControl.contentHeight = contentHeight * content.scaleY;
    }
  }
}