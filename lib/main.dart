import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

void main() {
  runApp(const MaterialApp(debugShowCheckedModeBanner: false,home: ExhibitionHallBuilder()));
}

class ExhibitionHallBuilder extends StatefulWidget {
  const ExhibitionHallBuilder({super.key});

  @override
  _ExhibitionHallBuilderState createState() => _ExhibitionHallBuilderState();
}

class _ExhibitionHallBuilderState extends State<ExhibitionHallBuilder> {
  List<Stall> stalls = [];
  double _scale = 1.0;
  Offset _position = Offset.zero;
  bool _isDragging = false;
  Offset _startPosition = Offset.zero;
  Stall? _hoveredStall;
  Stall? _selectedStall;

  // Hall size variables (in feet)
  double hallWidth = 100;
  double hallHeight = 80;
  final double maxHallSize = 500;

  // Grid size (in feet)
  final double gridSize = 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exhibition Hall Builder')),
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: _buildSidebar(),
          ),
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                GestureDetector(
                  onScaleStart: _handleScaleStart,
                  onScaleUpdate: _handleScaleUpdate,
                  child: MouseRegion(
                    onHover: _handleMouseHover,
                    child: ClipRect(
                      child: Transform(
                        transform: Matrix4.identity()
                          ..translate(_position.dx, _position.dy)
                          ..scale(_scale),
                        child: CustomPaint(
                          painter: HallPainter(
                            stalls: stalls,
                            hallWidth: hallWidth,
                            hallHeight: hallHeight,
                            gridSize: gridSize,
                            hoveredStall: _hoveredStall,
                            selectedStall: _selectedStall,
                          ),
                          child: Stack(
                            children: stalls
                                .map((stall) => _buildDraggableStall(stall))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 100,
                  child: _buildZoomControls(),
                ),
                Positioned(
                  left: 16,
                  bottom: 50,
                  child: _buildMinimap(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStallDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      color: Colors.grey[200],
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Hall Size',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Width (ft)'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      hallWidth = _validateHallSize(value);
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Height (ft)'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      hallHeight = _validateHallSize(value);
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Hall Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
              'Current Size: ${hallWidth.toStringAsFixed(1)}ft x ${hallHeight.toStringAsFixed(1)}ft'),
          Text('Number of Stalls: ${stalls.length}'),
          const SizedBox(height: 16),
          const Text('Stalls',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ...stalls
              .map((stall) => ListTile(
                    title: Text('${stall.width}x${stall.height} ft'),
                    subtitle: Text(
                        'Exhibitor: ${stall.exhibitorName}\nPrice: \$${stall.price}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editStall(stall),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeStall(stall),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildDraggableStall(Stall stall) {
    return Positioned(
      left: stall.position.dx,
      top: stall.position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            double newX = stall.position.dx + details.delta.dx;
            double newY = stall.position.dy + details.delta.dy;

            // Snap to grid
            newX = (newX / (gridSize * _scale)).round() * (gridSize * _scale);
            newY = (newY / (gridSize * _scale)).round() * (gridSize * _scale);

            // Ensure stall stays within hall bounds
            newX = newX.clamp(0, hallWidth * gridSize - stall.width * gridSize);
            newY =
                newY.clamp(0, hallHeight * gridSize - stall.height * gridSize);

            stall.position = Offset(newX, newY);
          });
        },
        onTap: () => _selectStall(stall),
        child: CustomTooltip(
          message: '${stall.width}x${stall.height}\n${stall.exhibitorName}',
          child: MouseRegion(
            onEnter: (_) => _hoverStall(stall),
            onExit: (_) => _unhoverStall(),
            child: Container(
              width: stall.width * gridSize,
              height: stall.height * gridSize,
              decoration: BoxDecoration(
                color: stall.color.withOpacity(0.5),
                border: Border.all(color: Colors.black),
              ),
              child: Center(
                child: Text(
                  '${stall.width}x${stall.height}\n${stall.exhibitorName}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          mini: true,
          child: const Icon(Icons.add),
          onPressed: () => setState(() => _scale *= 1.1),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          mini: true,
          child: const Icon(Icons.remove),
          onPressed: () => setState(() => _scale /= 1.1),
        ),
      ],
    );
  }

  Widget _buildMinimap() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
      ),
      child: CustomPaint(
        painter: MinimapPainter(
          stalls: stalls,
          hallWidth: hallWidth,
          hallHeight: hallHeight,
          hoveredStall: _hoveredStall,
          selectedStall: _selectedStall,
        ),
      ),
    );
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _isDragging = true;
    _startPosition = details.focalPoint;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      if (_isDragging) {
        _position += details.focalPoint - _startPosition;
        _startPosition = details.focalPoint;
      }
      _scale *= details.scale;
    });
  }

  void _handleMouseHover(PointerHoverEvent event) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(event.position);
    final transformedPosition = (localPosition - _position) / _scale;

    for (var stall in stalls) {
      if (_isPointInsideStall(transformedPosition, stall)) {
        _hoverStall(stall);
        return;
      }
    }
    _unhoverStall();
  }

  bool _isPointInsideStall(Offset point, Stall stall) {
    return point.dx >= stall.position.dx &&
        point.dx <= stall.position.dx + stall.width * gridSize &&
        point.dy >= stall.position.dy &&
        point.dy <= stall.position.dy + stall.height * gridSize;
  }

  void _hoverStall(Stall stall) {
    setState(() {
      _hoveredStall = stall;
    });
  }

  void _unhoverStall() {
    setState(() {
      _hoveredStall = null;
    });
  }

  void _selectStall(Stall stall) {
    setState(() {
      _selectedStall = stall;
    });
    _showStallInfoDialog(stall);
  }

  void _showStallInfoDialog(Stall stall) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Stall Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Size: ${stall.width}x${stall.height} ft'),
              Text('Exhibitor: ${stall.exhibitorName}'),
              Text('Price: \$${stall.price}'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _selectedStall = null;
                });
              },
            ),
            ElevatedButton(
              child: const Text('Buy'),
              onPressed: () {
                _buyStall(stall);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _buyStall(Stall stall) {
    setState(() {
      stall.color = Colors.green;
      stall.exhibitorName = 'Sold';
    });
  }

  void _showAddStallDialog() {
    int width = 10;
    int height = 10;
    String exhibitorName = '';
    double price = 0;
    Color stallColor = Colors.blue;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Stall'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Width (ft)'),
                          keyboardType: TextInputType.number,
                          onChanged: (value) =>
                              width = int.tryParse(value) ?? width,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Height (ft)'),
                          keyboardType: TextInputType.number,
                          onChanged: (value) =>
                              height = int.tryParse(value) ?? height,
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Exhibitor Name'),
                    onChanged: (value) => exhibitorName = value,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Price (\$)'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        price = double.tryParse(value) ?? price,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    child: const Text('Pick Color'),
                    onPressed: () async {
                      Color? color = await showColorPicker(context, stallColor);
                      if (color != null) {
                        setState(() => stallColor = color);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('Add'),
                  onPressed: () {
                    _addStall(width, height, exhibitorName, price, stallColor);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addStall(
      int width, int height, String exhibitorName, double price, Color color) {
    setState(() {
      stalls.add(Stall(
        position: const Offset(0, 0),
        width: width,
        height: height,
        color: color,
        exhibitorName: exhibitorName,
        price: price,
      ));
    });
  }

  void _editStall(Stall stall) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Stall'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Width (ft)'),
                          keyboardType: TextInputType.number,
                          controller: TextEditingController(
                              text: stall.width.toString()),
                          onChanged: (value) =>
                              stall.width = int.tryParse(value) ?? stall.width,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Height (ft)'),
                          keyboardType: TextInputType.number,
                          controller: TextEditingController(
                              text: stall.height.toString()),
                          onChanged: (value) => stall.height =
                              int.tryParse(value) ?? stall.height,
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Exhibitor Name'),
                    controller:
                        TextEditingController(text: stall.exhibitorName),
                    onChanged: (value) => stall.exhibitorName = value,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Price (\$)'),
                    keyboardType: TextInputType.number,
                    controller:
                        TextEditingController(text: stall.price.toString()),
                    onChanged: (value) =>
                        stall.price = double.tryParse(value) ?? stall.price,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    child: const Text('Change Color'),
                    onPressed: () async {
                      Color? color =
                          await showColorPicker(context, stall.color);
                      if (color != null) {
                        setState(() => stall.color = color);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('Save'),
                  onPressed: () {
                    setState(() {});
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removeStall(Stall stall) {
    setState(() {
      stalls.remove(stall);
    });
  }

  double _validateHallSize(String value) {
    double size = double.tryParse(value) ?? 0;
    return size.clamp(0, maxHallSize);
  }
}

class HallPainter extends CustomPainter {
  final List<Stall> stalls;
  final double hallWidth;
  final double hallHeight;
  final double gridSize;
  final Stall? hoveredStall;
  final Stall? selectedStall;

  HallPainter({
    required this.stalls,
    required this.hallWidth,
    required this.hallHeight,
    required this.gridSize,
    this.hoveredStall,
    this.selectedStall,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw hall outline
    canvas.drawRect(
        Rect.fromLTWH(0, 0, hallWidth * gridSize, hallHeight * gridSize),
        paint);

    // Draw grid
    for (double x = 0; x <= hallWidth; x += 1) {
      canvas.drawLine(Offset(x * gridSize, 0),
          Offset(x * gridSize, hallHeight * gridSize), paint);
    }
    for (double y = 0; y <= hallHeight; y += 1) {
      canvas.drawLine(Offset(0, y * gridSize),
          Offset(hallWidth * gridSize, y * gridSize), paint);
    }

    // Draw stalls
    for (var stall in stalls) {
      final stallPaint = Paint()
        ..color = stall.color.withOpacity(0.5)
        ..style = PaintingStyle.fill;

      final stallRect = Rect.fromLTWH(
        stall.position.dx,
        stall.position.dy,
        stall.width * gridSize,
        stall.height * gridSize,
      );

      canvas.drawRect(stallRect, stallPaint);

      if (stall == hoveredStall || stall == selectedStall) {
        final highlightPaint = Paint()
          ..color = Colors.yellow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawRect(stallRect, highlightPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MinimapPainter extends CustomPainter {
  final List<Stall> stalls;
  final double hallWidth;
  final double hallHeight;
  final Stall? hoveredStall;
  final Stall? selectedStall;

  MinimapPainter({
    required this.stalls,
    required this.hallWidth,
    required this.hallHeight,
    this.hoveredStall,
    this.selectedStall,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final scale = math.min(size.width / hallWidth, size.height / hallHeight);

    // Draw hall outline
    canvas.drawRect(
        Rect.fromLTWH(0, 0, hallWidth * scale, hallHeight * scale), paint);

    // Draw stalls
    for (var stall in stalls) {
      final stallPaint = Paint()
        ..color = stall.color.withOpacity(0.5)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(
          stall.position.dx * scale / 10,
          stall.position.dy * scale / 10,
          stall.width * scale,
          stall.height * scale,
        ),
        stallPaint,
      );

      if (stall == hoveredStall || stall == selectedStall) {
        final highlightPaint = Paint()
          ..color = Colors.yellow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawRect(
          Rect.fromLTWH(
            stall.position.dx * scale / 10,
            stall.position.dy * scale / 10,
            stall.width * scale,
            stall.height * scale,
          ),
          highlightPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Stall {
  Offset position;
  int width;
  int height;
  Color color;
  String exhibitorName;
  double price;

  Stall({
    required this.position,
    required this.width,
    required this.height,
    required this.color,
    required this.exhibitorName,
    required this.price,
  });
}

Future<Color?> showColorPicker(BuildContext context, Color initialColor) async {
  return showDialog<Color>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: initialColor,
            onColorChanged: (Color color) => initialColor = color,
            showLabel: true,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(initialColor);
            },
          ),
        ],
      );
    },
  );
}

class CustomTooltip extends StatefulWidget {
  final Widget child;
  final String message;

  CustomTooltip({required this.child, required this.message});

  @override
  _CustomTooltipState createState() => _CustomTooltipState();
}

class _CustomTooltipState extends State<CustomTooltip> {
  OverlayEntry? _overlayEntry;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _showTooltip(context),
      onExit: (_) => _hideTooltip(),
      child: widget.child,
    );
  }

  void _showTooltip(BuildContext context) {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: offset.dy + renderBox.size.height,
        left: offset.dx,
        child: Material(
          elevation: 4.0,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(widget.message),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _hideTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
