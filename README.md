# Shapes

This is a simple package for generating images containing 
shapes of various colors. The package can be compiled using:

```bash
swift build -c release
```

It can also be executed using (the example files can be 
replaced as needed):

```bash
swift run -c release shapes \ 
  --captions "Example/captions.txt" \
  --description-config "Example/description-config.json" \
  --generator-config "Example/generator-config.json" \
  --output-dir "Example/output"
```

This can also be executed by using the built `shapes` 
executable in the `.build` directory, directly. After 
executing successfully, the output directory (i.e.,  
`Example/output` in the example, above),  will contain 
text files with the requested and the full generated 
image captions, as well as the generated images in SVG 
format, in the `svg` subdirectory.

## PNG Images

For this functionality, you need to have the `rsvg-convert` 
package installed. For MacOS, you can install that using 
Homebrew, by executing `brew install librsvg`, and for 
Ubuntu, you can install it by executing 
`apt-get install librsvg2-bin`. Then, `shapes` can also 
convert the generated SVG images to PNG images, if one 
additional option is provided when executing:

```bash
swift run -c release shapes \
  --captions "Example/captions.txt" \
  --description-config "Example/description-config.json" \
  --generator-config "Example/generator-config.json" \
  --output-dir "Example/output" \
  --convert-to-png
```
