import '../../models/commands/feed_command.dart';

abstract class CommandHandler<T extends FeedCommand> {
  Future<CommandResult> handle(T command);
}
