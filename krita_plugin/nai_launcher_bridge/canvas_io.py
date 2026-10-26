import os
import tempfile
from pathlib import Path
from typing import Optional

from PyQt5.QtCore import QByteArray, QBuffer, QIODevice
from PyQt5.QtGui import QImage
from krita import InfoObject, Krita


MAX_V1_CANVAS_EDGE = 4096
PREVIEW_LAYER_NAME = "NAI Preview"
MASK_SOURCE_SELECTION = "selection"
_preview = None


def active_document():
    app = Krita.instance()
    if app is None:
        return None
    return app.activeDocument()


def has_active_document() -> bool:
    return active_document() is not None


def export_active_document_png() -> bytes:
    doc = active_document()
    if doc is None:
        raise RuntimeError("No active Krita document")
    _validate_v1_canvas(doc)

    try:
        return _export_projection_png(doc)
    except Exception:
        return _export_document_to_temp_png(doc)


def _export_projection_png(doc) -> bytes:
    # Use Krita's visible projection instead of raw pixel data to avoid
    # color-channel assumptions across document color spaces.
    projection = doc.projection(0, 0, doc.width(), doc.height())
    buffer = QBuffer()
    buffer.open(QIODevice.WriteOnly)
    if not projection.save(buffer, "PNG"):
        raise RuntimeError("Krita failed to encode the visible projection")
    return bytes(buffer.data())


def _export_document_to_temp_png(doc) -> bytes:
    with tempfile.NamedTemporaryFile(delete=False, suffix=".png") as handle:
        path = Path(handle.name)

    try:
        if not doc.exportImage(str(path), InfoObject()):
            raise RuntimeError("Krita failed to export the active document")
        return path.read_bytes()
    finally:
        try:
            path.unlink()
        except OSError:
            pass


def active_selection_bounds() -> Optional[dict]:
    doc = active_document()
    if doc is None:
        return None
    selection = doc.selection()
    if selection is None:
        return None
    width = selection.width()
    height = selection.height()
    if width <= 0 or height <= 0:
        return None
    return {
        "x": selection.x(),
        "y": selection.y(),
        "w": width,
        "h": height,
    }


def export_active_selection_mask_png() -> bytes:
    doc = active_document()
    if doc is None:
        raise RuntimeError("No active Krita document")
    _validate_v1_canvas(doc)
    selection = doc.selection()
    if selection is None or selection.width() <= 0 or selection.height() <= 0:
        raise RuntimeError("Create a Krita selection before inpaint")

    image = QImage(doc.width(), doc.height(), QImage.Format_Grayscale8)
    image.fill(0)
    has_repaint_pixels = False
    for y in range(selection.y(), selection.y() + selection.height()):
        for x in range(selection.x(), selection.x() + selection.width()):
            if _selection_pixel_value(selection, x, y) > 0:
                image.setPixel(x, y, 255)
                has_repaint_pixels = True

    if not has_repaint_pixels:
        raise RuntimeError("Inpaint mask is empty")

    buffer = QBuffer()
    buffer.open(QIODevice.WriteOnly)
    image.save(buffer, "PNG")
    return bytes(buffer.data())


def export_inpaint_mask_png(source: str = MASK_SOURCE_SELECTION) -> bytes:
    if source == MASK_SOURCE_SELECTION:
        return export_active_selection_mask_png()
    raise RuntimeError(f"Unknown inpaint mask source: {source}")


def write_png_preview(image_png: bytes) -> None:
    global _preview
    doc = active_document()
    layer = _write_png_as_layer(image_png, PREVIEW_LAYER_NAME)
    if not layer:
        raise RuntimeError("Krita failed to add preview layer")
    remove_preview_layer()
    _preview = (doc, layer)


def remove_preview_layer() -> None:
    global _preview
    if _preview is None:
        return
    doc, layer = _preview
    _preview = None
    _remove_node(doc.rootNode(), layer)
    _wait_for_done(doc)
    doc.refreshProjection()


def write_png_result(image_png: bytes, name: str) -> str:
    remove_preview_layer()
    return write_png_as_new_document(image_png, name)


def write_png_as_new_document(image_png: bytes, name: str) -> str:
    try:
        if _write_png_as_layer(image_png, name):
            return "layer"
    except Exception:
        pass

    with tempfile.NamedTemporaryFile(delete=False, suffix=".png") as handle:
        path = Path(handle.name)
        handle.write(image_png)

    try:
        doc = Krita.instance().openDocument(str(path))
        if doc is None:
            raise RuntimeError("Krita failed to open returned image")
        doc.setFileName("")
        if hasattr(doc, "setName"):
            doc.setName(name)
        window = Krita.instance().activeWindow()
        if window is None:
            raise RuntimeError("No active Krita window")
        window.addView(doc)
        return "document"
    finally:
        try:
            os.remove(str(path))
        except OSError:
            pass


def _write_png_as_layer(
    image_png: bytes,
    name: str,
):
    doc = active_document()
    if doc is None:
        return False
    _validate_v1_canvas(doc)

    image = QImage()
    if not image.loadFromData(QByteArray(image_png), "PNG"):
        return False
    image = image.convertToFormat(QImage.Format_RGBA8888)

    width = image.width()
    height = image.height()
    if width <= 0 or height <= 0:
        return False
    if width != doc.width() or height != doc.height():
        return False

    byte_count = (
        image.sizeInBytes() if hasattr(image, "sizeInBytes") else image.byteCount()
    )
    bits = image.bits()
    bits.setsize(byte_count)

    layer = doc.createNode(name, "paintLayer")
    layer.setPixelData(
        QByteArray(_rgba8888_to_krita_bgra(bits.asstring(byte_count))),
        0,
        0,
        width,
        height,
    )
    if not doc.rootNode().addChildNode(layer, None):
        return False
    _wait_for_done(doc)
    doc.refreshProjection()
    return layer


def _rgba8888_to_krita_bgra(raw: bytes) -> bytes:
    converted = bytearray(len(raw))
    for offset in range(0, len(raw), 4):
        red = raw[offset]
        green = raw[offset + 1]
        blue = raw[offset + 2]
        alpha = raw[offset + 3]
        converted[offset] = blue
        converted[offset + 1] = green
        converted[offset + 2] = red
        converted[offset + 3] = alpha
    return bytes(converted)


def _validate_v1_canvas(doc) -> None:
    if doc.width() < 64 or doc.height() < 64:
        raise RuntimeError("Canvas is too small for NAI Launcher bridge")
    if doc.width() > MAX_V1_CANVAS_EDGE or doc.height() > MAX_V1_CANVAS_EDGE:
        raise RuntimeError(
            "Canvas is too large for bridge V1; use a canvas up to 4096x4096"
        )


def _selection_pixel_value(selection, x: int, y: int) -> int:
    raw = bytes(selection.pixelData(x, y, 1, 1))
    if not raw:
        return 0
    return raw[0]


def _remove_node(root, node) -> None:
    if hasattr(node, "remove"):
        node.remove()
        return
    if hasattr(root, "removeChildNode"):
        root.removeChildNode(node)


def _wait_for_done(doc) -> None:
    if hasattr(doc, "waitForDone"):
        doc.waitForDone()
