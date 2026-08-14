require "test_helper"

class FaviconTest < ActiveSupport::TestCase
  PUBLIC = Rails.root.join("public")

  # Read width/height from PNG IHDR chunk.
  # Layout: 8-byte signature, 4-byte chunk length, 4-byte "IHDR", 4-byte width, 4-byte height
  def png_dimensions(path)
    data = File.binread(path.to_s, 24)
    raise "Not a PNG: #{path}" unless data[0, 8] == "\x89PNG\r\n\x1a\n".b
    data[16, 8].unpack("NN") # [width, height]
  end

  # Parse ICO directory to extract per-image sizes.
  # ICO binary layout: 6-byte header (reserved, type=1, count), then count×16-byte directory entries.
  # Directory entry byte 0 = width (0 means 256), byte 1 = height (0 means 256).
  def ico_sizes(path)
    data = File.binread(path.to_s)
    count = data[4, 2].unpack1("v")
    (0...count).map do |i|
      offset = 6 + i * 16
      w = data[offset].ord
      h = data[offset + 1].ord
      [ w.zero? ? 256 : w, h.zero? ? 256 : h ]
    end
  end

  test "favicon.ico is a valid multi-image ICO with 16, 32, and 48 layers" do
    path = PUBLIC.join("favicon.ico")
    assert File.exist?(path), "public/favicon.ico must exist"
    sizes = ico_sizes(path)
    widths = sizes.map(&:first)
    assert_includes widths, 16, "favicon.ico must contain a 16×16 layer"
    assert_includes widths, 32, "favicon.ico must contain a 32×32 layer"
    assert_includes widths, 48, "favicon.ico must contain a 48×48 layer"
    assert_equal 3, sizes.size, "favicon.ico must contain exactly 3 image layers"
  end

  {
    "favicon-16x16.png"      => [ 16, 16 ],
    "favicon-32x32.png"      => [ 32, 32 ],
    "apple-touch-icon.png"   => [ 180, 180 ],
    "icon-192.png"           => [ 192, 192 ],
    "icon-512.png"           => [ 512, 512 ],
    "icon.png"               => [ 512, 512 ],
    "icon-maskable-512.png"  => [ 512, 512 ],
    "favicon-dark-16x16.png" => [ 16, 16 ],
    "favicon-dark-32x32.png" => [ 32, 32 ],
  }.each do |filename, (expected_w, expected_h)|
    test "#{filename} exists and is #{expected_w}×#{expected_h}" do
      path = PUBLIC.join(filename)
      assert File.exist?(path), "public/#{filename} must exist"
      w, h = png_dimensions(path)
      assert_equal expected_w, w, "#{filename}: expected width #{expected_w}, got #{w}"
      assert_equal expected_h, h, "#{filename}: expected height #{expected_h}, got #{h}"
    end
  end

  test "icon.svg exists and contains SVG content" do
    path = PUBLIC.join("icon.svg")
    assert File.exist?(path), "public/icon.svg must exist"
    content = File.read(path)
    assert_includes content, "<svg", "icon.svg must contain an SVG element"
  end
end
