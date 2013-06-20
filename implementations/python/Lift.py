import sqlite3
import os.path
import uuid
from PIL import Image

# It's been a long time since I've done anything serious with Python
# So there are probably better ways to do things in here.

LiftImageSizTag = "imageSize"
LiftImageDPITag = "dpi"
LiftImageLayerFrameTag = "frame"

class LiftImage:
    
    def __init__(self):
        self.layers = []
        self.imageSize = (100, 100)
        pass
    
    def createContinerAtPath(self, path):
        conn = sqlite3.connect(path)
        conn.text_factory = str
        
        c = conn.cursor()
        
        c.execute('''create table layers (id text, parent_id text, sequence integer, uti text, name text, data blob)''');
        c.execute('''create table layer_attributes (id text, name text, value blob)''');
        c.execute('''create table image_attributes (name text, value blob)''');
        
        c.close()
        
        conn.commit()
        
        return conn
    
    def addLayer(self, layer):
        self.layers.append(layer);
    
    def storeAttribute(self, attName, attValue):
        
        c = self.conn.cursor()
        c.execute("delete from image_attributes where name = ?", (attName, ))
        
        if attValue:
            c.execute("insert into image_attributes (name, value) values (?,?)", (attName, attValue))
        
        self.conn.commit()
        
        c.close()
    
    def writeToPath(self, path):
        self.conn = self.createContinerAtPath(path)
        
        self.storeAttribute(LiftImageSizTag, ("{%d, %d}" % (self.imageSize[0], self.imageSize[1])));
        
        currentSeq = 0
        
        for l in self.layers:
            l.setSequence(currentSeq)
            l.writeToDBHandle(self.conn)
            currentSeq = currentSeq + 1

    def validateFileAtPath(self, path):
        pass


class LiftLayer:
    def __init__(self):
        
        self.id = str(uuid.uuid1())
        self.parent_id = None
        self.sequence = 0
        self.name = "Untitled Layer"
        self.data = None
        self.uti = "public.image"
        self.frame = (0, 0, 0, 0)
        
    def setSequence(self, newSequence):
        self.sequence = newSequence
    
    def setUTI(self, newUTI):
        self.uti = newUTI
    
    def setName(self, newName):
        self.name = newName
    
    def setLayerData(self, newLayerData):
        self.data = newLayerData
    
    
    def storeLayerAttribute(self, attName, attValue):
        
        c = self.conn.cursor()
        c.execute("delete from layer_attributes where id = ? and name = ?", (self.id, attName))
        
        if attValue:
            c.execute("insert into layer_attributes (id, name, value) values (?, ?, ?)", (self.id, attName, attValue))
        
        self.conn.commit()
        
        c.close()
    
    
    def writeToDBHandle(self, conn):
        
        self.conn = conn
        
        c = conn.cursor()
        c.execute("insert into layers (id, parent_id, sequence, uti, name, data) values (?, ?, ?, ?, ?, ?)", (self.id, self.parent_id, self.sequence, self.uti, self.name, sqlite3.Binary(self.data)))
        
        self.storeLayerAttribute(LiftImageLayerFrameTag, ("{%d, %d, %d, %d}" % (self.frame[0], self.frame[1], self.frame[2], self.frame[3])));
        
        conn.commit()
        c.close()
    
def utiForPath(path):

    extension = os.path.splitext(path)[1].lower()
    
    if (extension == '.jpg' or extension == '.jpeg'):
        return 'public.jpeg'
    elif (extension == '.tif' or extension == '.tiff'):
        return 'public.tiff'
    elif (extension == '.png'):
        return 'public.png'
    
    return None




