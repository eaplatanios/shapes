# Shapes

This is a simple package for generating images containing 
shapes of various colors. The package can be compiled using:

```bash
swift build -c release
```

It can be executed using either (the example files can be 
replaced as needed):

```bash
swift run -c release shapes \ 
  --descriptions "Examples/Small Example/descriptions.json" \
  --configuration "Examples/Small Example/configuration.json" \
  --output-dir "Examples/Small Example/Output"
```

or:

```bash
swift run -c release shapes \ 
  --captions "Examples/Small Example/captions.txt" \
  --configuration "Examples/Small Example/configuration.json" \
  --output-dir "Examples/Small Example/Output"
```

depending on the format in which the requested image
descriptions are provided. Feel free to take a look in the
provided example files to see the supported formats.

The image generator can also be executed by using the built
`shapes` executable in the `.build` directory, directly.
After executing successfully, the output directory (i.e.,  
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
  --captions "Examples/Small Example/captions.txt" \
  --configuration "Examples/Small Example/configuration.json" \
  --output-dir "Examples/Small Example/Output" \
  --convert-to-png
```
