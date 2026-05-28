///|
/// Binary reader for parsing font files
pub struct BinaryReader {
  data : BytesView
  mut pos : Int
} derive(Debug)

///|
/// Create a new binary reader
pub fn BinaryReader::new(data : Bytes) -> BinaryReader {
  { data: data[:], pos: 0 }
}

///|
/// Create a reader from a view
pub fn BinaryReader::from_view(data : BytesView) -> BinaryReader {
  { data, pos: 0 }
}

///|
/// Get current position
pub fn BinaryReader::tell(self : BinaryReader) -> Int {
  self.pos
}

///|
/// Seek to position
pub fn BinaryReader::seek(self : BinaryReader, pos : Int) -> Unit {
  self.pos = pos
}

///|
/// Skip n bytes
pub fn BinaryReader::skip(self : BinaryReader, n : Int) -> Unit {
  self.pos = self.pos + n
}

///|
/// Get remaining bytes
pub fn BinaryReader::remaining(self : BinaryReader) -> Int {
  self.data.length() - self.pos
}

///|
/// Read a single byte
pub fn BinaryReader::read_byte(self : BinaryReader) -> Byte {
  guard self.pos < self.data.length() else { abort("Unexpected end of data") }
  let b = self.data[self.pos]
  self.pos = self.pos + 1
  b
}

///|
/// Read n bytes
pub fn BinaryReader::read_bytes(self : BinaryReader, n : Int) -> BytesView {
  guard self.pos + n <= self.data.length() else {
    abort("Unexpected end of data")
  }
  let result = self.data[self.pos:self.pos + n]
  self.pos = self.pos + n
  result
}

///|
/// Read UInt16 big-endian
pub fn BinaryReader::read_u16_be(self : BinaryReader) -> UInt16 {
  let hi = self.read_byte().to_uint16()
  let lo = self.read_byte().to_uint16()
  (hi << 8) | lo
}

///|
/// Read UInt32 big-endian
pub fn BinaryReader::read_u32_be(self : BinaryReader) -> UInt {
  let b1 = self.read_byte().to_uint()
  let b2 = self.read_byte().to_uint()
  let b3 = self.read_byte().to_uint()
  let b4 = self.read_byte().to_uint()
  (b1 << 24) | (b2 << 16) | (b3 << 8) | b4
}

///|
/// Read Int16 big-endian (as Int)
pub fn BinaryReader::read_i16_be(self : BinaryReader) -> Int {
  let val = self.read_u16_be().to_int()
  if val > 32767 {
    val - 65536
  } else {
    val
  }
}

///|
/// Read Int32 big-endian (as Int)
pub fn BinaryReader::read_i32_be(self : BinaryReader) -> Int {
  self.read_u32_be().to_int()
}

///|
/// Read a tag (4-byte ASCII string)
pub fn BinaryReader::read_tag(self : BinaryReader) -> String {
  let b0 = self.read_byte()
  let b1 = self.read_byte()
  let b2 = self.read_byte()
  let b3 = self.read_byte()

  // Build string using StringBuilder with byte-to-char conversion
  let sb = StringBuilder()
  sb.write_char(b0.to_uint16().unsafe_to_char())
  sb.write_char(b1.to_uint16().unsafe_to_char())
  sb.write_char(b2.to_uint16().unsafe_to_char())
  sb.write_char(b3.to_uint16().unsafe_to_char())
  sb.to_string()
}
