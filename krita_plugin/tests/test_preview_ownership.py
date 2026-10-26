"""Real preview/request logic with in-memory Qt, documents and pixels."""
import base64
import types
import unittest

import test_canvas_io as canvas_fixture
import test_ui_state as ui_fixture


class PreviewOwnershipTests(unittest.TestCase):
    def setUp(self):
        ui = ui_fixture._load_ui_module()
        self.canvas = canvas_fixture._load_canvas_io()
        self.a = canvas_fixture.FakeLayerDoc(64, 64)
        self.b = canvas_fixture.FakeLayerDoc(64, 64)
        self.active = self.a
        self.canvas.Krita = types.SimpleNamespace(instance=lambda: types.SimpleNamespace(
            activeDocument=lambda: self.active))
        self.canvas.QImage = canvas_fixture.FakeLoadedQImage
        self.canvas._export_projection_png = lambda doc: b'synthetic-source'
        ui.canvas_io = self.canvas
        self.docker = ui.NAILauncherBridgeDocker()

    def start(self):
        self.docker._send_img2img()
        self.request = self.docker._active_request_id
        self.assertIsNotNone(self.request)

    def progress(self, request=None):
        self.docker._last_preview_at = None
        self.docker._handle_message({
            'type': 'progress', 'id': request or self.request, 'progress': .5,
            'preview_image': base64.b64encode(b'preview-pixels').decode('ascii'),
        })

    def nodes(self, doc):
        return doc.root.childNodes()

    def test_switching_document_cleans_owned_preview_and_drops_other_document_frames(self):
        self.start()
        self.progress()
        self.assertEqual(len(self.nodes(self.a)), 1)
        self.active = self.b
        self.docker.canvasChanged(self.b)
        self.assertEqual(self.nodes(self.a), [])
        self.progress()
        self.assertEqual(self.nodes(self.b), [])
        self.active = self.a
        self.docker.canvasChanged(self.a)
        self.progress()
        self.assertEqual(len(self.nodes(self.a)), 1)

    def test_cancel_after_switch_cleans_request_preview_without_touching_user_layer(self):
        self.start()
        self.progress()
        user = canvas_fixture.FakeLayer(self.canvas.PREVIEW_LAYER_NAME)
        self.b.root.addChildNode(user, None)
        self.active = self.b
        self.docker._handle_message({'type': 'cancelled', 'id': self.request})
        self.assertEqual(self.nodes(self.a), [])
        self.assertEqual(self.nodes(self.b), [user])

    def test_export_preserves_unowned_same_name_layers_and_groups(self):
        user = canvas_fixture.FakeLayer(self.canvas.PREVIEW_LAYER_NAME)
        group = canvas_fixture.FakeLayer(self.canvas.PREVIEW_LAYER_NAME)
        child = canvas_fixture.FakeLayer(self.canvas.PREVIEW_LAYER_NAME)
        group.childNodes = lambda: [child]
        self.a.root.addChildNode(user, None)
        self.a.root.addChildNode(group, None)
        self.docker._export_clean_canvas()
        self.assertEqual(self.nodes(self.a), [user, group])

    def test_preview_replacement_removes_only_the_previous_owned_node(self):
        user = canvas_fixture.FakeLayer(self.canvas.PREVIEW_LAYER_NAME)
        self.a.root.addChildNode(user, None)
        self.canvas.write_png_preview(b'first')
        previous = self.nodes(self.a)[-1]
        previous._name = 'renamed preview'
        self.canvas.write_png_preview(b'second')
        self.assertEqual(len(self.nodes(self.a)), 2)
        self.assertIs(self.nodes(self.a)[0], user)
        self.assertNotIn(previous, self.nodes(self.a))
        self.canvas.remove_preview_layer()
        self.canvas.remove_preview_layer()
        self.assertEqual(self.nodes(self.a), [user])

    def test_manual_result_preview_uses_the_current_document(self):
        self.start()
        self.progress()
        self.active = self.b
        self.canvas.write_png_preview(b'manual-result')
        self.assertEqual(self.nodes(self.a), [])
        self.assertEqual(len(self.nodes(self.b)), 1)
        self.canvas.remove_preview_layer()
        self.assertEqual(self.nodes(self.b), [])

    def test_no_document_or_unrelated_request_does_not_write_preview(self):
        self.start()
        self.progress('unrelated-request')
        self.assertEqual(self.nodes(self.a), [])
        self.active = None
        self.docker.canvasChanged(None)
        self.progress()
        self.assertEqual(self.nodes(self.a), [])
        self.docker._handle_message({'type': 'cancelled', 'id': self.request})
        self.assertIsNone(self.docker._active_request_id)


if __name__ == '__main__':
    unittest.main()
