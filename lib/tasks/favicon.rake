namespace :favicons do
  desc "Regenerate all favicons and app icons from high-res source assets"
  task :generate do
    source_light = Rails.root.join("app/assets/images/logo/daybreak-mark-light.png").to_s
    source_dark  = Rails.root.join("app/assets/images/logo/daybreak-mark-dark.png").to_s
    source_svg   = Rails.root.join("app/assets/images/logo/daybreak-mark.svg").to_s
    public_dir   = Rails.root.join("public").to_s
    bg_light     = "#F3EBE2"

    def run(cmd)
      puts cmd
      system(cmd) || raise("ImageMagick command failed: #{cmd}")
    end

    # Light mark PNGs — resize from 1024px source
    run "convert '#{source_light}' -resize 16x16  -depth 8 -type TrueColorAlpha '#{public_dir}/favicon-16x16.png'"
    run "convert '#{source_light}' -resize 32x32  -depth 8 -type TrueColorAlpha '#{public_dir}/favicon-32x32.png'"
    run "convert '#{source_light}' -resize 192x192 -depth 8 -type TrueColorAlpha '#{public_dir}/icon-192.png'"
    run "convert '#{source_light}' -resize 512x512 -depth 8 -type TrueColorAlpha '#{public_dir}/icon-512.png'"
    run "convert '#{source_light}' -resize 512x512 -depth 8 -type TrueColorAlpha '#{public_dir}/icon.png'"

    # Apple touch icon: 180×180, small safe-area margin (~10px per side)
    # Resize mark to 160×160, extend to 180×180 on light background
    run "convert '#{source_light}' -resize 160x160 -background '#{bg_light}' " \
        "-gravity center -extent 180x180 -depth 8 -type TrueColorAlpha '#{public_dir}/apple-touch-icon.png'"

    # Maskable icon: 20% safe-area padding on all sides
    # Content area = 512 * 0.6 = ~307px; mark fills that, padded to 512×512 on light background
    run "convert '#{source_light}' -resize 307x307 -background '#{bg_light}' " \
        "-gravity center -extent 512x512 -depth 8 -type TrueColorAlpha '#{public_dir}/icon-maskable-512.png'"

    # Dark mark PNGs
    run "convert '#{source_dark}' -resize 16x16 -depth 8 -type TrueColorAlpha '#{public_dir}/favicon-dark-16x16.png'"
    run "convert '#{source_dark}' -resize 32x32 -depth 8 -type TrueColorAlpha '#{public_dir}/favicon-dark-32x32.png'"

    # Multi-resolution ICO: 16×16, 32×32, 48×48, 32-bit RGBA
    # Build each size explicitly from the source to ensure crisp rendering at each size
    run "convert " \
        "\\( '#{source_light}' -resize 16x16 -type TrueColorAlpha \\) " \
        "\\( '#{source_light}' -resize 32x32 -type TrueColorAlpha \\) " \
        "\\( '#{source_light}' -resize 48x48 -type TrueColorAlpha \\) " \
        "'#{public_dir}/favicon.ico'"

    # SVG: copy vector source
    require "fileutils"
    FileUtils.cp(source_svg, "#{public_dir}/icon.svg")
    puts "Done. All favicons regenerated."
  end
end
