# Layered Image File Type Specification

THIS IS A WORK IN PROGRESS - gus@flyingmeat.com

A lift image is a SQLite 3 database which contains three tables storing data and attributes on the layers which make up the image.

There are three tables in a lift image - image_attributes, layers, and layer_attributes.

All fields are case sensitive and any text is stored as UTF-8.

File extension is '.lift', and the UTI is 'org.liftimage.lift'

# image_attributes
`create table image_attributes (name text, value blob)`  
The image_attributes table is a key value store for attributes on the image.  Things like color space, image size (in pixels), dpi, bits per component, and even a composite of all the layers.

### Required rows for image_attributes

**imageSize**: This is used to store the dimensions of the image in the format {width,height}.  For example, '{900,600}' would the the size of an image that is 900 pixels wide and 600 pixels high.

**iccColorProfile**: The ICC profile data for the image.

**Optional rows for image_attributes**

**bitsPerComponent**: A single unsigned integer storing the number of bits used per component in the image.

**bitsPerPixel**: A single unsigned integer storing the number of bits per pixel for the image.

**composite**: A bitmap composite of all the visible layers (recommended to be stored as a tiff or png image)
**composite-uti**: The UTI of the image composite.

**dpi**: The dots per inch for the composited image, stored in the format of '{dpiwidth,dpiheight}'.  For example '{72,72}'.
If no dpi key is present, the default value of {72,72} will be assumed.

### Vendor Specific Keys
Any other keys placed in the image_attributes are not required and can either be ignored or used for vendor specific purposes.  It is required that you prefix your keys with the bundle id / reverse domain name of your application so that application specific keys will not interfere with future versions of the lift spec.  For example, Acorn stores a setting for the blend mode of it's grid.  This key is stored as 'com.flyingmeat.acorn.gridBlendMode'


# layers
`create table layers (id text, parent_id text, sequence integer, uti text, name text, data blob)`  
The layers table stores basic information about a single layer in the image.  
The id field is a UUID string for the layer.  
The parent_id is the UUID of the layer group this layer is enclosed by.  If parent_id is null, then the layer is a top level layer.  
The sequence field is used to denote the order of the layers in the parent layer group.  
the uti field is the Uniform Type Identifier for the layer.  http://en.wikipedia.org/wiki/Uniform_Type_Identifier  
The name field is the user visible name of the layer.  
The data field is the data for the layer.  

If the layer data is stored as TIFF then the UTI would be 'public.tiff'.  PNG would be 'public.png'.  It is recommended that the layer data not be stored in a lossy format (such as JPEG).

The UTI for group layers is 'org.liftimage.grouplayer'

If the layer data is proprietary, then you would come up with your own UTI.  For instance, Acorn stores its shape layer data in a proprietary format and uses the UTI of 'com.flyingmeat.acorn.shape-layer'.

# layer_attributes
`create table layer_attributes (id text, name text, value blob)`  
The layer_attributes table stores key value information for a single layer.

### Required rows for layer_attributes

…

### Optional rows for layer_attributes

**frame**: If the layer is a bitmap (such as TIFF or PNG) then a frame row is highly recommended.  It is a string in the format of {xOrigin, yOrigin, width, height}.  For example: {0, 0, 800, 600} or {-10, 46, 100, 1230}.  If not present, then it readers must default to a origin of 0,0 and width/height of the layer image.

**visible**: A boolean value (1|0) which lets an app know if the layer should be composited with the rest of the layers.

**locked**: A boolean value (1|0) which lets an editor know if the layer is locked for editing or not.

**blendMode**: A string which represents the blending / compositing mode of the layer.  Examples include normal, passThrough, multiply, screen, overlay, darken, lighten, colorDodge, colorBurn, softLight, hardLight, difference, exclusion, hue, saturation, color, luminosity, clear, copy, sourceIn, sourceOut, sourceAtop, destintionOver, destinationIn, destinationOut, destinationAtop, xor, plusDarker, plusLighter, divide, linearBurn, linearDodge, lighterColor, darkerColor, subtract, hardmix.  A default of "normal" will be used if not present.

**opacity**: A float value representing the opacity of the layer.  A default value of 1.0 must be used if not present.

### Vendor Specific Keys

*Note* - maybe the vendor specific keys should use a reverse domain name prefix similar to what UTIs do?



### Open questions.

**Composite data**  
If an application which provides features such as non-destructive filters on layers (also known as layer styles), should a composite of the layer be stored as an attribute of the layer?  And if it does, maybe a specific key should be used?  Maybe 'lift.composite' and 'lift.composite-uti' to store the uti of the composite (tiff/jpeg/png)?

**Intercaps, dashes, or underscores?**  
Table names can't have dashes, but they can have intercaps or underscores.  
Apple's UTIs have dashes in them, and never use intercaps.

SO, should the key for a blend mode be:  
'blendMode'  
'blend_mode'  
'blend-mode'  

AND - should it have a lift prefix on it?  
'lift.blend-mode' ?



file version info should be stored outside image_attributes.
Do we need a 'document_attributes' table which would describe the particular format, the author, copyright, etc?



