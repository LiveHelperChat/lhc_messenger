import 'package:flutter/material.dart';

class AnimateExpanded extends StatefulWidget {
  AnimateExpanded(
      {required this.title,
      required this.subtitle,
      required this.contentWidgetList});
  final String title;
  final String subtitle;
  final List<Widget> contentWidgetList;
  @override
  _AnimateExpandedState createState() => new _AnimateExpandedState();
}

class _AnimateExpandedState extends State<AnimateExpanded> {
  bool _isExpanded = false;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Card(
            child: SizedBox(
              height: 65.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: ListTile(
                      title: Text(widget.title),
                      subtitle: Text(
                        widget.subtitle,
                        style: new TextStyle(fontSize: 10.0),
                        overflow: TextOverflow.fade,
                      ),
                      trailing: IconButton(
                        icon: _isExpanded
                            ? new Icon(Icons.keyboard_arrow_up)
                            : new Icon(Icons.keyboard_arrow_down),
                        onPressed: () {
                          setState(() {
                            this._isExpanded
                                ? this._isExpanded = false
                                : this._isExpanded = true;
                          });
                        },
                      ),
                    ),
                  ),
                  /*       new Expanded(
                     child:new Padding(
                         padding:const EdgeInsets.all(12.0),
                         child: new Text(widget.title ?? "") )),

               new IconButton(icon: _isExpanded ? new Icon(Icons.keyboard_arrow_up) :new Icon(Icons.keyboard_arrow_down) , onPressed: () {
                    setState((){
                      this._isExpanded ? this._isExpanded =false :this._isExpanded =true;
                    });
                  },)  */
                ],
              ),
            ),
          ),
          /*new Card(
            child:
          ), */
          AnimatedContainer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.contentWidgetList,
            ),
            curve: Curves.easeInOut,
            duration: const Duration(milliseconds: 500),
            height: _isExpanded ? 100.0 : 0.0,
            //width:100.0,
            // color: Colors.red,
          ),
        ],
      ),
    );
  }
}
