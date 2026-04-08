import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show MethodChannel, rootBundle;

const _kChannel = MethodChannel('palletier/clipboard');

class GvmlClipboard {
  String? _contentTypesXml;
  String? _relsXml;
  String? _drawingRelsXml;
  String? _theme1Xml;

  /// Load the fixed GVML template files from assets. Call once at startup.
  Future<void> init() async {
    _contentTypesXml =
        await rootBundle.loadString('assets/gvml_templates/content_types.xml');
    _relsXml =
        await rootBundle.loadString('assets/gvml_templates/rels.xml');
    _drawingRelsXml =
        await rootBundle.loadString('assets/gvml_templates/drawing_rels.xml');
    _theme1Xml =
        await rootBundle.loadString('assets/gvml_templates/theme1.xml');
  }

  /// Copy a colored rectangle to clipboard as PowerPoint shape.
  Future<void> copyRectangle(String hexColor) async {
    await _copyShape('rect', hexColor, 1500000, 1500000);
  }

  /// Copy a colored circle to clipboard as PowerPoint shape.
  Future<void> copyEllipse(String hexColor) async {
    await _copyShape('ellipse', hexColor, 1500000, 1500000);
  }

  Future<void> _copyShape(
      String shapeType, String hexColor, int cx, int cy) async {
    final drawingXml = _buildDrawingXml(
      shapeType: shapeType,
      hexColor: hexColor.replaceFirst('#', ''),
      cx: cx,
      cy: cy,
    );

    final zipBytes = await _buildZip(drawingXml);

    await _kChannel.invokeMethod('setGvmlClipboard', zipBytes);
  }

  String _buildDrawingXml({
    required String shapeType,
    required String hexColor,
    required int cx,
    required int cy,
  }) {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">'
        '<a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/lockedCanvas">'
        '<lc:lockedCanvas xmlns:lc="http://schemas.openxmlformats.org/drawingml/2006/lockedCanvas">'
        '<a:nvGrpSpPr><a:cNvPr id="0" name=""/><a:cNvGrpSpPr/></a:nvGrpSpPr>'
        '<a:grpSpPr><a:xfrm>'
        '<a:off x="0" y="0"/>'
        '<a:ext cx="$cx" cy="$cy"/>'
        '<a:chOff x="0" y="0"/>'
        '<a:chExt cx="$cx" cy="$cy"/>'
        '</a:xfrm></a:grpSpPr>'
        '<a:sp>'
        '<a:nvSpPr><a:cNvPr id="2" name="Shape 1"/><a:cNvSpPr/></a:nvSpPr>'
        '<a:spPr>'
        '<a:xfrm><a:off x="0" y="0"/><a:ext cx="$cx" cy="$cy"/></a:xfrm>'
        '<a:prstGeom prst="$shapeType"><a:avLst/></a:prstGeom>'
        '<a:solidFill><a:srgbClr val="$hexColor"/></a:solidFill>'
        '<a:ln><a:noFill/></a:ln>'
        '</a:spPr>'
        '<a:txSp>'
        '<a:txBody><a:bodyPr rtlCol="0" anchor="ctr"/>'
        '<a:lstStyle>'
        '<a:defPPr><a:defRPr lang="ko-KR"/></a:defPPr>'
        '<a:lvl1pPr marL="0" algn="l" defTabSz="914400" rtl="0" eaLnBrk="1" latinLnBrk="1" hangingPunct="1">'
        '<a:defRPr sz="1800" kern="1200">'
        '<a:solidFill><a:schemeClr val="lt1"/></a:solidFill>'
        '<a:latin typeface="+mn-lt"/><a:ea typeface="+mn-ea"/><a:cs typeface="+mn-cs"/>'
        '</a:defRPr></a:lvl1pPr>'
        '</a:lstStyle>'
        '<a:p><a:pPr algn="ctr"/><a:endParaRPr lang="ko-KR" altLang="en-US"/></a:p>'
        '</a:txBody><a:useSpRect/>'
        '</a:txSp>'
        '<a:style>'
        '<a:lnRef idx="2"><a:schemeClr val="accent1"><a:shade val="15000"/></a:schemeClr></a:lnRef>'
        '<a:fillRef idx="1"><a:schemeClr val="accent1"/></a:fillRef>'
        '<a:effectRef idx="0"><a:schemeClr val="accent1"/></a:effectRef>'
        '<a:fontRef idx="minor"><a:schemeClr val="lt1"/></a:fontRef>'
        '</a:style>'
        '</a:sp>'
        '</lc:lockedCanvas>'
        '</a:graphicData>'
        '</a:graphic>';
  }

  /// Build GVML ZIP using PowerShell with explicit entry names.
  Future<Uint8List> _buildZip(String drawingXml) async {
    final tempDir = await Directory.systemTemp.createTemp('gvml_');
    final d = tempDir.path;
    final zipPath = '$d\\gvml.zip';

    // Write each file to temp dir (flat, numbered for easy reference)
    final files = {
      '[Content_Types].xml': _contentTypesXml!,
      '_rels/.rels': _relsXml!,
      'clipboard/drawings/drawing1.xml': drawingXml,
      'clipboard/drawings/_rels/drawing1.xml.rels': _drawingRelsXml!,
      'clipboard/theme/theme1.xml': _theme1Xml!,
    };

    // Write temp files and build PowerShell add-entry commands
    final addCommands = StringBuffer();
    var i = 0;
    for (final entry in files.entries) {
      final tmpFile = '$d\\f$i.xml';
      await File(tmpFile).writeAsString(entry.value);
      final entryName = entry.key;
      addCommands.writeln(
        '[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile('
        '\$zip, "$tmpFile", "$entryName") | Out-Null',
      );
      i++;
    }

    final ps = 'Add-Type -AssemblyName System.IO.Compression\n'
        'Add-Type -AssemblyName System.IO.Compression.FileSystem\n'
        '\$zip = [System.IO.Compression.ZipFile]::Open("$zipPath", "Create")\n'
        '${addCommands.toString()}'
        '\$zip.Dispose()\n';

    final result = await Process.run(
      'powershell',
      ['-NoProfile', '-Command', ps],
    );

    if (result.exitCode != 0 || !await File(zipPath).exists()) {
      await tempDir.delete(recursive: true);
      throw Exception('Failed to create ZIP: ${result.stderr}');
    }

    final zipBytes = await File(zipPath).readAsBytes();
    await tempDir.delete(recursive: true);
    return zipBytes;
  }
}
