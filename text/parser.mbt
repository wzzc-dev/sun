///|
/// Parse a TTF font file
pub fn parse_font(data : Bytes) -> Font {
  let reader = BinaryReader::new(data)

  // Read offset table
  let sf_version = reader.read_u32_be()
  guard sf_version == 0x00010000 else { abort("Invalid font header") }

  let num_tables = reader.read_u16_be().to_int()
  ignore(reader.read_u16_be()) // searchRange
  ignore(reader.read_u16_be()) // entrySelector
  ignore(reader.read_u16_be()) // rangeShift

  // Read table directory
  let tables : Map[String, TableRecord] = {}
  for _ in 0..<num_tables {
    let tag = reader.read_tag()
    let checksum = reader.read_u32_be()
    let offset = reader.read_u32_be()
    let length = reader.read_u32_be()
    tables[tag] = { tag, checksum, offset, length }
  }

  // Parse head table
  let head = parse_head(data, tables)
  // Parse hhea table
  let hhea = parse_hhea(data, tables)
  // Parse hmtx table
  let hmtx = parse_hmtx(data, tables, hhea.num_h_metrics)
  // Parse cmap table
  let cmap = parse_cmap(data, tables)
  // Parse maxp table to get numGlyphs
  let num_glyphs = parse_maxp(data, tables)
  // Parse loca table
  let loca = parse_loca(data, tables, head.index_to_loc_format, num_glyphs)
  let (glyphs, glyph_count) = parse_glyf(data, tables, loca)
  // Parse kern table
  let kern = parse_kern(data, tables)

  { head, hhea, hmtx, cmap, glyphs, glyph_count, kern }
}

///|
/// Parse head table
fn parse_head(data : Bytes, tables : Map[String, TableRecord]) -> FontHead {
  let table = match tables.get("head") {
    Some(t) => t
    None => abort("head table not found")
  }
  let reader = BinaryReader::from_view(data[table.offset.to_int():])

  ignore(reader.read_u32_be()) // version
  ignore(reader.read_u32_be()) // fontRevision
  ignore(reader.read_u32_be()) // checkSumAdjustment
  ignore(reader.read_u32_be()) // magicNumber
  ignore(reader.read_u16_be()) // flags
  let units_per_em = reader.read_u16_be().to_int()
  ignore(reader.read_bytes(8)) // created
  ignore(reader.read_bytes(8)) // modified
  ignore(reader.read_i16_be()) // xmin
  ignore(reader.read_i16_be()) // ymin
  ignore(reader.read_i16_be()) // xmax
  ignore(reader.read_i16_be()) // ymax
  ignore(reader.read_u16_be()) // macStyle
  ignore(reader.read_u16_be()) // lowestRecPPEM
  ignore(reader.read_i16_be()) // fontDirectionHint
  let index_to_loc_format = reader.read_i16_be()
  ignore(reader.read_i16_be()) // glyphDataFormat

  { units_per_em, index_to_loc_format }
}

///|
/// Parse hhea table
fn parse_hhea(data : Bytes, tables : Map[String, TableRecord]) -> FontHhea {
  let table = match tables.get("hhea") {
    Some(t) => t
    None => abort("hhea table not found")
  }
  let reader = BinaryReader::from_view(data[table.offset.to_int():])

  ignore(reader.read_u32_be()) // version
  let ascent = reader.read_i16_be()
  let descent = reader.read_i16_be()
  let line_gap = reader.read_i16_be()
  ignore(reader.read_u16_be()) // advanceWidthMax
  ignore(reader.read_i16_be()) // minLeftSideBearing
  ignore(reader.read_i16_be()) // minRightSideBearing
  ignore(reader.read_i16_be()) // xMaxExtent
  ignore(reader.read_i16_be()) // caretSlopeRise
  ignore(reader.read_i16_be()) // caretSlopeRun
  ignore(reader.read_i16_be()) // caretOffset
  ignore(reader.read_bytes(8)) // reserved
  ignore(reader.read_i16_be()) // metricDataFormat
  let num_h_metrics = reader.read_u16_be().to_int()

  { ascent, descent, line_gap, num_h_metrics }
}

///|
/// Parse hmtx table
fn parse_hmtx(
  data : Bytes,
  tables : Map[String, TableRecord],
  num_h_metrics : Int,
) -> Array[LongHorMetric] {
  let table = match tables.get("hmtx") {
    Some(t) => t
    None => abort("hmtx table not found")
  }
  let reader = BinaryReader::from_view(data[table.offset.to_int():])
  let metrics = []

  for _ in 0..<num_h_metrics {
    let advance_width = reader.read_u16_be().to_int()
    let lsb = reader.read_i16_be()
    metrics.push({ advance_width, lsb })
  }

  metrics
}

///|
/// Parse cmap table (supports format 4 and format 12)
fn parse_cmap(data : Bytes, tables : Map[String, TableRecord]) -> Map[Int, Int] {
  let table = match tables.get("cmap") {
    Some(t) => t
    None => abort("cmap table not found")
  }
  let base_offset = table.offset.to_int()
  let reader = BinaryReader::from_view(data[base_offset:])
  let cmap : Map[Int, Int] = {}

  ignore(reader.read_u16_be()) // version
  let num_tables = reader.read_u16_be().to_int()

  // Collect encoding records
  let mut format4_offset = 0
  let mut format12_offset = 0
  for _ in 0..<num_tables {
    let platform_id = reader.read_u16_be().to_int()
    let encoding_id = reader.read_u16_be().to_int()
    let offset = reader.read_u32_be().to_int()

    // Prefer format 12 (full Unicode) over format 4 (BMP only)
    if platform_id is 0 && encoding_id is 4 {
      // Unicode 2.0+ full repertoire
      format12_offset = offset
    } else if platform_id is 3 && encoding_id is 10 {
      // Windows Unicode full repertoire
      format12_offset = offset
    } else if platform_id is 3 && encoding_id is 1 {
      // Windows Unicode BMP (format 4)
      format4_offset = offset
    }
  }

  // Try format 12 first, then format 4
  if format12_offset > 0 {
    let result = parse_cmap_format12(data, base_offset + format12_offset)
    if result.length() > 0 {
      return result
    }
  }

  if format4_offset > 0 {
    return parse_cmap_format4(data, base_offset + format4_offset)
  }

  cmap
}

///|
/// Parse cmap format 4 subtable (BMP characters)
fn parse_cmap_format4(data : Bytes, offset : Int) -> Map[Int, Int] {
  let cmap : Map[Int, Int] = {}
  let reader = BinaryReader::from_view(data[offset:])

  let format = reader.read_u16_be().to_int()
  guard format is 4 else { return cmap }

  ignore(reader.read_u16_be()) // length
  ignore(reader.read_u16_be()) // language
  let seg_count = reader.read_u16_be().to_int() / 2
  ignore(reader.read_u16_be()) // searchRange
  ignore(reader.read_u16_be()) // entrySelector
  ignore(reader.read_u16_be()) // rangeShift

  // Read end codes
  let end_codes = []
  for _ in 0..<seg_count {
    end_codes.push(reader.read_u16_be().to_int())
  }
  ignore(reader.read_u16_be()) // reservedPad
  // Read start codes
  let start_codes = []
  for _ in 0..<seg_count {
    start_codes.push(reader.read_u16_be().to_int())
  }
  // Read id deltas
  let id_deltas = []
  for _ in 0..<seg_count {
    id_deltas.push(reader.read_i16_be())
  }
  // Read id range offsets
  let id_range_offsets = []
  let offsets_start = reader.tell()
  for _ in 0..<seg_count {
    id_range_offsets.push(reader.read_u16_be().to_int())
  }

  // Build cmap
  for i in 0..<seg_count {
    let start = start_codes[i]
    let end = end_codes[i]
    let delta = id_deltas[i]
    let range_offset = id_range_offsets[i]

    for c in start..<=end {
      let glyph_id = if range_offset is 0 {
        (c + delta) % 65536
      } else {
        // Calculate offset into glyphIdArray
        let off = offsets_start + i * 2
        let glyph_offset = off + range_offset + (c - start) * 2
        if glyph_offset + 2 <= data.length() {
          let gid = (data[glyph_offset].to_int() << 8) +
            data[glyph_offset + 1].to_int()
          if gid is 0 {
            0
          } else {
            (gid + delta) % 65536
          }
        } else {
          0
        }
      }
      if glyph_id > 0 {
        cmap[c] = glyph_id
      }
    }
  }

  cmap
}

///|
/// Parse cmap format 12 subtable (full Unicode repertoire)
fn parse_cmap_format12(data : Bytes, offset : Int) -> Map[Int, Int] {
  let cmap : Map[Int, Int] = {}
  let reader = BinaryReader::from_view(data[offset:])

  let format = reader.read_u16_be().to_int()
  guard format is 12 else { return cmap }

  ignore(reader.read_u16_be()) // reserved
  let length = reader.read_u32_be().to_int()
  ignore(reader.read_u32_be()) // language
  let n_groups = reader.read_u32_be().to_int()

  // Read groups
  for _ in 0..<n_groups {
    let start_char_code = reader.read_u32_be().to_int()
    let end_char_code = reader.read_u32_be().to_int()
    let start_glyph_id = reader.read_u32_be().to_int()

    // Map each character in the range
    for c in start_char_code..<=end_char_code {
      let glyph_id = start_glyph_id + (c - start_char_code)
      cmap[c] = glyph_id
    }
  }

  cmap
}

///|
/// Parse maxp table to get numGlyphs
fn parse_maxp(data : Bytes, tables : Map[String, TableRecord]) -> Int {
  let table = match tables.get("maxp") {
    Some(t) => t
    None => abort("maxp table not found")
  }
  let reader = BinaryReader::from_view(data[table.offset.to_int():])

  ignore(reader.read_u32_be()) // version
  let num_glyphs = reader.read_u16_be().to_int()

  num_glyphs
}

///|
/// Parse loca table
fn parse_loca(
  data : Bytes,
  tables : Map[String, TableRecord],
  index_to_loc_format : Int,
  num_glyphs : Int,
) -> Array[Int] {
  let table = match tables.get("loca") {
    Some(t) => t
    None => abort("loca table not found")
  }
  let reader = BinaryReader::from_view(data[table.offset.to_int():])
  let offsets = []

  // Number of entries = numGlyphs + 1
  let num_entries = num_glyphs + 1

  for _ in 0..<num_entries {
    if index_to_loc_format is 0 {
      offsets.push(reader.read_u16_be().to_int() * 2) // short format: multiply by 2
    } else {
      offsets.push(reader.read_u32_be().to_int()) // long format
    }
  }

  offsets
}

///|
/// Parse glyf table
fn parse_glyf(
  data : Bytes,
  tables : Map[String, TableRecord],
  loca : Array[Int],
) -> (Array[GlyphData], Int) {
  let table = match tables.get("glyf") {
    Some(t) => t
    None => abort("glyf table not found")
  }
  let glyf_offset = table.offset.to_int()
  let glyph_count = loca.length() - 1
  let glyphs = []

  // Parse glyphs (increased limit for CJK fonts)
  // CJK fonts typically have 20000+ glyphs
  let max_glyphs = if glyph_count > 65536 { 65536 } else { glyph_count }
  for i in 0..<max_glyphs {
    let offset = loca[i]
    let next_offset = loca[i + 1]

    if offset >= next_offset {
      glyphs.push(GlyphData::Empty)
    } else {
      let glyph_data = parse_glyph(data[glyf_offset + offset:])
      glyphs.push(glyph_data)
    }
  }
  // Fill remaining with Empty
  for i in max_glyphs..<glyph_count {
    glyphs.push(GlyphData::Empty)
  }

  (glyphs, glyph_count)
}

///|
/// Parse a single glyph
fn parse_glyph(data : BytesView) -> GlyphData {
  let reader = BinaryReader::from_view(data)
  let num_contours = reader.read_i16_be()
  let xmin = reader.read_i16_be()
  let ymin = reader.read_i16_be()
  let xmax = reader.read_i16_be()
  let ymax = reader.read_i16_be()

  guard num_contours > 0 else {
    // Composite glyph (num_contours == -1)
    return parse_composite_glyph(reader)
  }

  // Simple glyph
  let end_pts_of_contour = []
  for _ in 0..<num_contours {
    end_pts_of_contour.push(reader.read_u16_be().to_int())
  }

  let instruction_length = reader.read_u16_be().to_int()
  ignore(reader.read_bytes(instruction_length)) // instructions

  let num_points = end_pts_of_contour[num_contours - 1] + 1

  // Read flags
  let flags : Array[Int] = []
  let mut i = 0
  while i < num_points {
    let flag = reader.read_byte().to_int()
    flags.push(flag)
    if flag.land(0x08) != 0 {
      // Repeat flag
      let repeat_count = reader.read_byte().to_int()
      for _ in 0..<repeat_count {
        flags.push(flag)
      }
      i = i + repeat_count + 1
    } else {
      i = i + 1
    }
  }

  // Read x coordinates
  let x_coords = []
  let mut prev_x = 0
  for idx in 0..<num_points {
    let flag = flags[idx]
    let dx = if flag.land(0x02) != 0 {
      // Short vector
      let val = reader.read_byte().to_int()
      if flag.land(0x10) != 0 {
        val
      } else {
        -val
      }
    } else if flag.land(0x10) != 0 {
      0
    } else {
      reader.read_i16_be()
    }
    prev_x = prev_x + dx
    x_coords.push(prev_x)
  }

  // Read y coordinates
  let y_coords = []
  let mut prev_y = 0
  for idx in 0..<num_points {
    let flag = flags[idx]
    let dy = if flag.land(0x04) != 0 {
      // Short vector
      let val = reader.read_byte().to_int()
      if flag.land(0x20) != 0 {
        val
      } else {
        -val
      }
    } else if flag.land(0x20) != 0 {
      0
    } else {
      reader.read_i16_be()
    }
    prev_y = prev_y + dy
    y_coords.push(prev_y)
  }

  // Build contours
  let contours = []
  let mut point_start = 0
  for ci in 0..<num_contours {
    let point_end = end_pts_of_contour[ci] + 1
    let points = []
    for pi in point_start..<point_end {
      let on_curve = flags[pi].land(0x01) != 0
      points.push({ x: x_coords[pi], y: y_coords[pi], on_curve })
    }
    contours.push({ points, })
    point_start = point_end
  }

  GlyphData::Simple({ contours, xmin, ymin, xmax, ymax })
}

///|
/// Parse a composite glyph
fn parse_composite_glyph(reader : BinaryReader) -> GlyphData {
  let components = []

  // Composite glyph flags
  let arg_1_and_2_are_words = 0x0001
  let args_are_xy_values = 0x0002
  let we_have_a_scale = 0x0008
  let more_components = 0x0020
  let we_have_an_x_and_y_scale = 0x0040
  let we_have_a_two_by_two = 0x0080

  let mut has_more = true
  while has_more {
    let flags = reader.read_u16_be().to_int()
    let glyph_index = reader.read_u16_be().to_int()

    // Read offset/argument values
    let (x_offset, y_offset) = if flags.land(arg_1_and_2_are_words) != 0 {
      let x = reader.read_i16_be()
      let y = reader.read_i16_be()
      (x, y)
    } else {
      let arg1 = reader.read_byte().to_int()
      let arg2 = reader.read_byte().to_int()
      if flags.land(args_are_xy_values) != 0 {
        (arg1, arg2)
      } else {
        (0, 0)
      }
    }

    // Read scale values
    let (scale_x, scale_y, scale_xy, scale_yx) = if flags.land(we_have_a_scale) !=
      0 {
      let s = reader.read_i16_be().to_double() / 16384.0
      (s, s, 0.0, 0.0)
    } else if flags.land(we_have_an_x_and_y_scale) != 0 {
      let sx = reader.read_i16_be().to_double() / 16384.0
      let sy = reader.read_i16_be().to_double() / 16384.0
      (sx, sy, 0.0, 0.0)
    } else if flags.land(we_have_a_two_by_two) != 0 {
      let sx = reader.read_i16_be().to_double() / 16384.0
      let sxy = reader.read_i16_be().to_double() / 16384.0
      let syx = reader.read_i16_be().to_double() / 16384.0
      let sy = reader.read_i16_be().to_double() / 16384.0
      (sx, sy, sxy, syx)
    } else {
      (1.0, 1.0, 0.0, 0.0)
    }

    components.push({
      glyph_index,
      x_offset,
      y_offset,
      scale_x,
      scale_y,
      scale_xy,
      scale_yx,
    })

    has_more = flags.land(more_components) != 0
  }

  GlyphData::Composite(components)
}

///|
/// Parse kern table
fn parse_kern(
  data : Bytes,
  tables : Map[String, TableRecord],
) -> Array[KernPair] {
  let kern = []

  match tables.get("kern") {
    Some(table) => {
      let reader = BinaryReader::from_view(data[table.offset.to_int():])

      // Read version
      let version = reader.read_u16_be().to_int()
      guard version is 0 else { return kern }

      // Read number of subtables
      let n_tables = reader.read_u16_be().to_int()

      for _ in 0..<n_tables {
        // Read subtable header
        ignore(reader.read_u16_be()) // version
        let length = reader.read_u16_be().to_int()
        let coverage = reader.read_u16_be().to_int()

        // Only support format 0 (horizontal kerning)
        let format = (coverage >> 8).land(0xFF)
        guard format is 0 else {
          // Skip this subtable
          ignore(reader.read_bytes(length - 6))
          continue
        }

        let n_pairs = reader.read_u16_be().to_int()
        ignore(reader.read_u16_be()) // searchRange
        ignore(reader.read_u16_be()) // entrySelector
        ignore(reader.read_u16_be()) // rangeShift

        for _ in 0..<n_pairs {
          let left = reader.read_u16_be().to_int()
          let right = reader.read_u16_be().to_int()
          let value = reader.read_i16_be()
          kern.push({ left, right, value })
        }
      }
    }
    None =>
      // No kern table
      ignore(0)
  }

  kern
}
