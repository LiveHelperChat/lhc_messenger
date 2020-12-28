import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AnimateExpanded extends StatefulWidget {
  AnimateExpanded({this.title,this.subtitle,@required this.contentWidgetList});
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
    return  new SingleChildScrollView(
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          new Card(
            child: new Container(
              height: 65.0,
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
              new Expanded(child:  new ListTile(
                    title: new Text(widget.title ?? ""),
                  subtitle: new Text(widget.subtitle ?? "",style: new TextStyle(fontSize: 10.0),overflow: TextOverflow.fade,),
                  trailing: new IconButton(icon: _isExpanded ? new Icon(Icons.keyboard_arrow_up) :new Icon(Icons.keyboard_arrow_down) , onPressed: () {
                    setState((){
                      this._isExpanded ? this._isExpanded =false :this._isExpanded =true;
                    });
                  },) ,),),
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
          new AnimatedContainer(
              child: new Row(
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