import '../models/action_item.dart';
import '../models/automation.dart';
import '../models/condition_branch.dart';
import '../models/tag_scan_log.dart';
import 'database_service.dart';
import 'pc_connection_service.dart';

class AutomationEngineResult {
  final ConditionBranch? matchedBranch;
  final bool executed;
  final String? error;
  final List<ActionExecutionResult> actionResults;

  AutomationEngineResult({
    this.matchedBranch,
    this.executed = false,
    this.error,
    this.actionResults = const [],
  });
}

class ActionExecutionResult {
  final ActionItem action;
  final bool success;
  final String? message;

  ActionExecutionResult({
    required this.action,
    required this.success,
    this.message,
  });
}

class AutomationEngine {
  final DatabaseService _db = DatabaseService();

  /// Find and execute the automation linked to a tag UID
  Future<AutomationEngineResult> executeForTag(String tagUid) async {
    final automation = await _db.getAutomationByTagUid(tagUid);
    if (automation == null) {
      return AutomationEngineResult(error: 'No automation linked');
    }
    return executeAutomation(automation, tagUid);
  }

  /// Evaluate conditions and find the matching branch, then execute actions
  Future<AutomationEngineResult> executeAutomation(
      Automation automation, String tagUid) async {
    if (!automation.isEnabled) {
      return AutomationEngineResult(error: 'Automation is disabled');
    }

    ConditionBranch? matchedBranch;
    for (final branch in automation.branches) {
      if (await branch.evaluate()) {
        matchedBranch = branch;
        break;
      }
    }

    if (matchedBranch == null) {
      await _logScan(
          tagUid, automation.name, null, false, 'No condition matched');
      return AutomationEngineResult(error: 'No condition matched');
    }

    // Execute all actions in the matched branch
    final actionResults = <ActionExecutionResult>[];
    for (final action in matchedBranch.actions) {
      if (action.delayMs > 0) {
        await Future.delayed(Duration(milliseconds: action.delayMs));
      }

      final result = await _executeAction(action);
      actionResults.add(result);
    }

    final allSuccess = actionResults.every((r) => r.success);
    await _logScan(
        tagUid, automation.name, matchedBranch.label, allSuccess, null);

    return AutomationEngineResult(
      matchedBranch: matchedBranch,
      executed: true,
      actionResults: actionResults,
    );
  }

  Future<ActionExecutionResult> _executeAction(ActionItem action) async {
    if (action.target == ActionTarget.pc) {
      return _executePcAction(action);
    } else {
      return _executePhoneAction(action);
    }
  }

  Future<ActionExecutionResult> _executePcAction(ActionItem action) async {
    final pcService = PcConnectionService();
    if (!pcService.isConnected) {
      return ActionExecutionResult(
        action: action,
        success: false,
        message: 'PC not connected',
      );
    }

    final result = await pcService.sendAction(action);
    if (result == null) {
      return ActionExecutionResult(
        action: action,
        success: false,
        message: 'No response from PC',
      );
    }

    return ActionExecutionResult(
      action: action,
      success: result['success'] == true,
      message: result['error'] as String?,
    );
  }

  Future<ActionExecutionResult> _executePhoneAction(ActionItem action) async {
    // Phone actions are handled by the phone_action_service
    // For now, return success as placeholder
    // TODO: Implement actual phone action execution via platform channels
    return ActionExecutionResult(
      action: action,
      success: true,
      message: 'Phone action: ${action.actionType}',
    );
  }

  Future<void> _logScan(String tagUid, String automationName,
      String? branchLabel, bool success, String? error) async {
    final tag = await _db.getTagByUid(tagUid);
    await _db.insertScanLog(TagScanLog(
      tagUid: tagUid,
      tagNickname: tag?.nickname,
      scannedAt: DateTime.now(),
      automationName: automationName,
      branchMatched: branchLabel,
      success: success,
      errorMessage: error,
    ));
  }
}
