# Zap (Zafar's audio player)

This repository contains a Matlab GUI which implements Zafar's audio player (Zap), featuring some practical functionalities such as a synchronized spectrogram, a select/drag tool, and a playback line.

- [zap Matlab GUI](#zap-matlab-gui)
- [audio_file](#audio_file)
- [Author](#author)

## zap Matlab GUI

Toolbar's toggle buttons:

- [Open](#open)
- [Play/Stop](#playstop)
- [Select/Drag](#selectdrag)
- [Zoom](#zoom)
- [Pan](#pan)

### Open

- Select a WAVE or MP3 to open (the audio can be multichannel).
- Display the audio signal and the audio spectrogram (in dB); the horizontal limits of the signal and spectrogram axes will be synchronized (and will stay synchronized if a zoom or a pan is applied on any of the axes).

<img src="images/zap_open1.png" width="1000">
<img src="images/zap_open2.png" width="1000">

### Play/Stop

- Play the audio if the playback is not in progress; stop the audio if the playback is in progress.
- A playback line will be displayed as the playback is in progress.
- If there is no selection line or region, the audio will be played from the start to the end; if there is a selection line, the audio will be played from the selection line to the end of the audio; if there is a selection region, the audio will be played from the start to the end of the selection region.

<img src="images/zap_play1.png" width="1000">

<img src="images/zap_play2.png" width="1000">

### Select/Drag

- If a left mouse click is done on the signal axes, a selection line is created; the audio will be played from the selection line to the end of the audio.
- If a left mouse click and drag is done on the signal axes or on a selection line, a selection region is created; the audio will be played from the start to the end of the selection region.
- If a left mouse click and drag is done on the left or right boundary of a selection region, the selection region is resized.
- If a right mouse click is done on the signal axes, any selection line or region is removed.

<img src="images/zap_select1.png" width="1000">

<img src="images/zap_select2.png" width="1000">

<img src="images/zap_drag1.png" width="1000">

<img src="images/zap_drag2.png" width="1000">

### Zoom

- Zoom in by positioning the mouse cursor where you want the center of the plot to be and either

  - Press the mouse button or

  - Rotate the mouse scroll wheel away from you (upward).

- Zoom out by positioning the mouse cursor where you want the center of the plot to be and either

  - Simultaneously press Shift and the mouse button, or

  - Rotate the mouse scroll wheel toward you (downward).

- Clicking and dragging over an axes when zooming in is enabled draws a rubberband box. When you release the mouse button, the axes zoom in to the region enclosed by the rubberband box.

- Double-clicking over an axes returns the axes to its initial zoom setting in both zoom-in and zoom-out modes.

- If used on the signal axes, zoom in horizontally only; the horizontal limits of the signal and spectrogram axes will stay synchronized.


<img src="images/zap_zoom1.png" width="1000">

<img src="images/zap_zoom2.png" width="1000">

### Pan

- Pan ...
; the horizontal limits of the signal and spectrogram axes will stay synchronized.

<img src="images/zap_pan1.png" width="1000">

<img src="images/zap_pan2.png" width="1000">


## audio_file

- Tamy - Que Pena / Tanto Faz (excerpt)

## Author

- Zafar Rafii
- zafarrafii@gmail.com
- [Website](http://zafarrafii.com/)
- [CV](http://zafarrafii.com/Zafar%20Rafii%20-%20C.V..pdf)
- [Google Scholar](https://scholar.google.com/citations?user=8wbS2EsAAAAJ&hl=en)
- [LinkedIn](https://www.linkedin.com/in/zafarrafii/)
