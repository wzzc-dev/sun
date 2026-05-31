///|
/// Replayable CPU render command.
pub enum RenderCommand {
  Clear(@graphics.Color)
  FillRect(Double, Double, Double, Double, @graphics.Paint)
  StrokeRect(Double, Double, Double, Double, @graphics.Paint)
  FillPath(@graphics.Path, @graphics.Paint)
  StrokePath(@graphics.Path, @graphics.Paint)
  DrawPixmap(@graphics.Pixmap, Int, Int, @graphics.Paint)
  DrawPixmapRect(
    @graphics.Pixmap,
    @graphics.PixelRect,
    Int,
    Int,
    @graphics.Paint
  )
  DrawTextFace(
    @text.FontFace,
    String,
    Double,
    Double,
    @text.LayoutConfig,
    @graphics.Paint
  )
} derive(Debug)

///|
/// Ordered list of CPU render commands.
pub struct RenderPipeline {
  commands : Array[RenderCommand]
} derive(Debug)

///|
/// Telemetry returned after replaying a render pipeline.
pub struct RenderPipelineReplayResult {
  command_count : Int
  clear_count : Int
  fill_count : Int
  stroke_count : Int
  image_count : Int
  text_count : Int
} derive(Eq, Debug)

///|
/// Create an empty render pipeline.
pub fn RenderPipeline::new() -> RenderPipeline {
  { commands: [] }
}

///|
/// Return the number of queued commands.
pub fn RenderPipeline::len(self : RenderPipeline) -> Int {
  self.commands.length()
}

///|
/// Return whether this pipeline has no queued commands.
pub fn RenderPipeline::is_empty(self : RenderPipeline) -> Bool {
  self.len() is 0
}

///|
/// Return the queued commands.
pub fn RenderPipeline::get_commands(
  self : RenderPipeline,
) -> Array[RenderCommand] {
  self.commands
}

///|
/// Drop all queued commands.
pub fn RenderPipeline::clear_commands(self : RenderPipeline) -> Unit {
  self.commands.clear()
}

///|
/// Append an already constructed command.
pub fn RenderPipeline::push(
  self : RenderPipeline,
  command : RenderCommand,
) -> RenderPipeline {
  self.commands.push(command)
  self
}

///|
/// Queue a canvas clear command.
pub fn RenderPipeline::clear_canvas(
  self : RenderPipeline,
  color : @graphics.Color,
) -> RenderPipeline {
  self.push(RenderCommand::Clear(color))
}

///|
/// Queue a filled rectangle command.
pub fn RenderPipeline::fill_rect(
  self : RenderPipeline,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  paint : @graphics.Paint,
) -> RenderPipeline {
  self.push(RenderCommand::FillRect(x, y, width, height, paint))
}

///|
/// Queue a stroked rectangle command.
pub fn RenderPipeline::stroke_rect(
  self : RenderPipeline,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  paint : @graphics.Paint,
) -> RenderPipeline {
  self.push(RenderCommand::StrokeRect(x, y, width, height, paint))
}

///|
/// Queue a filled path command.
pub fn RenderPipeline::fill_path(
  self : RenderPipeline,
  path : @graphics.Path,
  paint : @graphics.Paint,
) -> RenderPipeline {
  self.push(RenderCommand::FillPath(path, paint))
}

///|
/// Queue a stroked path command.
pub fn RenderPipeline::stroke_path(
  self : RenderPipeline,
  path : @graphics.Path,
  paint : @graphics.Paint,
) -> RenderPipeline {
  self.push(RenderCommand::StrokePath(path, paint))
}

///|
/// Queue a pixmap draw command.
pub fn RenderPipeline::draw_pixmap(
  self : RenderPipeline,
  pixmap : @graphics.Pixmap,
  x : Int,
  y : Int,
  paint : @graphics.Paint,
) -> RenderPipeline {
  self.push(RenderCommand::DrawPixmap(pixmap, x, y, paint))
}

///|
/// Queue a source-rectangle pixmap draw command.
pub fn RenderPipeline::draw_pixmap_rect(
  self : RenderPipeline,
  pixmap : @graphics.Pixmap,
  src_rect : @graphics.PixelRect,
  x : Int,
  y : Int,
  paint : @graphics.Paint,
) -> RenderPipeline {
  self.push(RenderCommand::DrawPixmapRect(pixmap, src_rect, x, y, paint))
}

///|
/// Queue a text draw command using an already parsed font face.
pub fn RenderPipeline::draw_text_face(
  self : RenderPipeline,
  face : @text.FontFace,
  text : String,
  x : Double,
  y : Double,
  config : @text.LayoutConfig,
  paint : @graphics.Paint,
) -> RenderPipeline {
  self.push(RenderCommand::DrawTextFace(face, text, x, y, config, paint))
}

///|
/// Return the number of commands replayed.
pub fn RenderPipelineReplayResult::get_command_count(
  self : RenderPipelineReplayResult,
) -> Int {
  self.command_count
}

///|
/// Return the number of clear commands replayed.
pub fn RenderPipelineReplayResult::get_clear_count(
  self : RenderPipelineReplayResult,
) -> Int {
  self.clear_count
}

///|
/// Return the number of fill commands replayed.
pub fn RenderPipelineReplayResult::get_fill_count(
  self : RenderPipelineReplayResult,
) -> Int {
  self.fill_count
}

///|
/// Return the number of stroke commands replayed.
pub fn RenderPipelineReplayResult::get_stroke_count(
  self : RenderPipelineReplayResult,
) -> Int {
  self.stroke_count
}

///|
/// Return the number of image commands replayed.
pub fn RenderPipelineReplayResult::get_image_count(
  self : RenderPipelineReplayResult,
) -> Int {
  self.image_count
}

///|
/// Return the number of text commands replayed.
pub fn RenderPipelineReplayResult::get_text_count(
  self : RenderPipelineReplayResult,
) -> Int {
  self.text_count
}

///|
/// Replay all queued commands through this renderer.
pub fn Renderer::draw_pipeline(
  self : Renderer,
  pipeline : RenderPipeline,
) -> RenderPipelineReplayResult {
  pipeline.replay(self)
}

///|
/// Replay all queued commands through a renderer.
pub fn RenderPipeline::replay(
  self : RenderPipeline,
  renderer : Renderer,
) -> RenderPipelineReplayResult {
  let canvas = renderer.get_canvas()
  let mut clear_count = 0
  let mut fill_count = 0
  let mut stroke_count = 0
  let mut image_count = 0
  let mut text_count = 0
  for command in self.commands {
    match command {
      RenderCommand::Clear(color) => {
        canvas.clear(color)
        clear_count += 1
      }
      RenderCommand::FillRect(x, y, width, height, paint) => {
        canvas.fill_rect(x, y, width, height, paint)
        fill_count += 1
      }
      RenderCommand::StrokeRect(x, y, width, height, paint) => {
        canvas.stroke_rect(x, y, width, height, paint)
        stroke_count += 1
      }
      RenderCommand::FillPath(path, paint) => {
        canvas.fill_path(path, paint)
        fill_count += 1
      }
      RenderCommand::StrokePath(path, paint) => {
        canvas.stroke_path(path, paint)
        stroke_count += 1
      }
      RenderCommand::DrawPixmap(pixmap, x, y, paint) => {
        canvas.draw_pixmap(pixmap, x, y, paint)
        image_count += 1
      }
      RenderCommand::DrawPixmapRect(pixmap, src_rect, x, y, paint) => {
        canvas.draw_pixmap_rect(pixmap, src_rect, x, y, paint)
        image_count += 1
      }
      RenderCommand::DrawTextFace(face, text, x, y, config, paint) => {
        renderer.draw_text_face(face, text, x, y, config, paint)
        text_count += 1
      }
    }
  }
  {
    command_count: self.commands.length(),
    clear_count,
    fill_count,
    stroke_count,
    image_count,
    text_count,
  }
}
