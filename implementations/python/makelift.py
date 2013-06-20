import sys
import Lift
from PIL import Image

l = Lift.LiftImage()

outPath = sys.argv[1]


for imageFile in sys.argv[2:]:
    
    layerUTI = Lift.utiForPath(imageFile)
    if layerUTI is None:
        print("Not sure what the UTI for %s is supposed to be" % imageFile)
        continue
    
    layer = Lift.LiftLayer()

    f = open(imageFile, 'rb')
    data = f.read()
    f.close()

    layer.setLayerData(data)
    layer.setUTI(layerUTI)

    # get the width and height of the image using PIL
    im = Image.open(imageFile)

    layer.frame = (0, 0, im.size[0], im.size[1])
    
    l.addLayer(layer)


l.writeToPath(outPath)



