package wotstat.cef.buttons {
  import flash.display.Graphics;

  public class Close extends Button {
    private const WIDTH:int = 18;
    private const X_OFFSET:int = 6;

    public function Close() {
      super(WIDTH, 10, drawContent);
    }

    private function drawContent(graphics:Graphics, size:Number, radius:Number):void {
      graphics.lineStyle(1, 0xffffff);
      graphics.moveTo(X_OFFSET, X_OFFSET);
      graphics.lineTo(size - X_OFFSET, size - X_OFFSET);
      graphics.moveTo(size - X_OFFSET, X_OFFSET);
      graphics.lineTo(X_OFFSET, size - X_OFFSET);
    }
  }
}