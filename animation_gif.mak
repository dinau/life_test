#### Genarate animation gif from img/*.png files
# https://kimizuka.hatenablog.com/entry/2018/05/26/204618
# -r FPS    # number per sec
IMG_DIR = img
PALETTE = palette.png
OUT_GIF = anim.gif
OUT_COMP_GIF = anim_comp.gif

.PHONY: img pall comp

img: palette
	( cd $(IMG_DIR);ffmpeg -f image2 -r 5 -i %04d.png -i $(PALETTE) -filter_complex paletteuse $(OUT_GIF) )
	-@ls  -al $(IMG_DIR)/$(PALETTE)
	-@ls -al $(IMG_DIR)/*.gif

# make palette
palette:
	( cd $(IMG_DIR);ffmpeg -i %04d.png -vf palettegen $(PALETTE) )

# compress gif
comp:
	( cd $(IMG_DIR);gifsicle -O3 --colors=128 --lossy=90 $(OUT_GIF) -o $(OUT_COMP_GIF))
	-@ls  -al $(IMG_DIR)/$(OUT_COMP_GIF)


