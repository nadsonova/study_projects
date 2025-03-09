import torch
from torch.utils.data import Dataset
from PIL import Image
import numpy as np
import random

class ImgDataset(Dataset):
    def __init__(self,
                 img_X,
                 img_Y,
                 img_transform,
                 mask_size=None,
                 mask_transform=None):
        self.img_X = img_X
        self.img_Y = img_Y
        self.img_transform = img_transform
        self.mask_size = mask_size
        self.mask_transform = mask_transform

    def __getitem__(self, i):
        # https://github.com/pytorch/vision/issues/9#issuecomment-304224800
        seed = np.random.randint(2147483647)

        img = Image.fromarray((self.img_X[0,...,0]*255).astype(np.uint8))
        mask = Image.fromarray((self.img_Y[0,...,0]).astype(np.uint8))

        if self.img_transform is not None:
            random.seed(seed)
            img = self.img_transform(img)

        if self.mask_size is None or self.mask_transform is None:
             raise ValueError('If mask_dpath is not None, mask_size and mask_transform must not be None.')
        else:
             random.seed(seed)
             mask = self.mask_transform(mask)

        return img, torch.from_numpy(np.array(mask, dtype=np.int64))
    
    def __len__(self):
        return len(self.img_X)