abstract class Enum<T> {
final T value;
const Enum(this.value);
}

class ChatItemMenuOption<int> extends Enum<int> {
const ChatItemMenuOption(int val) : super(val);
static const ChatItemMenuOption ACCEPT = const ChatItemMenuOption(1);
static const ChatItemMenuOption CLOSE = const ChatItemMenuOption(2);
static const ChatItemMenuOption REJECT = const ChatItemMenuOption(3);
static const ChatItemMenuOption TRANSFER = const ChatItemMenuOption(4);
static const ChatItemMenuOption PREVIEW = const ChatItemMenuOption(5);
}