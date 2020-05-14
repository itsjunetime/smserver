import Foundation

@objc protocol IMDServiceSession {

    //var _account: IMDAccount { get set }
    var _accounts: Array<Any> { get set }
    var _activated: Bool { get set }
    var _awaitingDataContext: Bool { get set }
    var _badPass: Bool { get set }
    //var _buddies: Dictionary { get set }
    var _buddyChangeLevel: Int { get set }
    //var _changedBuddies: Set { get set }
    //var _chatRoomToGroupChatIdentifierMap: Dictionary { get set }
    //var _chatSuppressionFlagMap: Dictionary { get set }
    //var _chatSuppressionTimerMap: Dictionary { get set }
    //var _connectionMonitor: IMConnectionMonitor { get set }
    //var _groupChatIdentifierToChatRoomMap: Dictionary { get set }
    //var _localProperties: Dictionary { get set }
    var _lock: NSRecursiveLock { get set }
    //var _loginID: Stirng { get set }
    //var _messageAutoReplier: IMDAutoReplying { get set }
    //var _messageExpireStateTimer: IMTimer { get set }
    //var _messageRoutingTimer: IMTimer { get set }
    //var _messageWatchdogTimer: IMTimer { get set }
    var _messagesProcessedComingBackFromStorage: CUnsignedLongLong { get set }
    //var _messagesReceivedDuringStorage: Set { get set }
    //var _otcUtilities: IMOneTimeCodeUtilities { get set }
    var _password: String { get set }
    var _pendingReadReceiptFromStorageCount: CUnsignedLongLong { get set }
    var _proxyAccount: String { get set }
    var _proxyHost: String { get set }
    var _proxyPassword: String { get set }
    var _proxyPort: CUnsignedShort { get set }
    var _proxyType: CLongLong { get set }
    var _pwRequestID: String { get set }
    //var _reconnectTimer: NSTimer { get set }
    //var _registeredChats: Set { get set }
    var _saveKeychainPassword: Bool { get set }
    var _serverHost: String { get set }
    var _serverPort: CUnsignedShort { get set }
    //var _service: IMDService { get set }
    var _shouldReconnect: Bool { get set }
    //var _storageTimer: NSTimer { get set }
    //var _suppressedMessages: Dictionary { get set }
    //var _systemProxySettingsFetcher: IMSystemProxySettingsFetcher { get set }
    //var _timingComingBackFromStorage: IMTimingCollection { get set }
    var _useSSL: Bool { get set }
    
    func sendMessage(_: Any, toChat: Any, style: CUnsignedChar, account: Any) -> Void
    func sendMessage(_: Any, toChatID: Any, identifier: Any, style: CUnsignedChar) -> Void
    func __allServiceSessionsWeakReferenceArray(_: Any) -> Any
    func __registerNewServiceSession(_: Any) -> Void
    func _firewallUserNotificationForService(_: Any) -> Any
    func allServiceSessions(_: Any) -> Any
    func existingServiceSessionForService(_: Any) -> Any
    func initialize(_: Any) -> Void
    func __forceSetLoginStatus(_: CUnsignedInt, oldStatus: CUnsignedInt, message: Any, properties: Any) -> Void
    func _abandonPWFetcher(_: Any) -> Void
    func _abandonSystemProxySettingsFetcher(_: Any) -> Void
    func _autoReconnectTimer(_: Any) -> Void
    func _autoReplier(_: Any) -> Any
    func _callMonitorStateChanged(_: Any) -> Void
    func _checkMessageForOneTimeCodes(_: Any) -> Void
    func _clearAutoReconnectTimer(_: Any) -> Void
    func _clearConnectionMonitor(_: Any) -> Void
    func _clearDowngradeMarkersForChat(_: Any) -> Void
    func _data_connection_readyWithAccount(_: Any) -> Void
    func _didReceiveMessageDeliveryReceiptForMessageID(_: Any, attempts: CLongLong, date: Any) -> Bool
    func _didReceiveMessagePlayedForMessageID(_: Any, date: Any, attempts: CLongLong, useMessageSuppression: Bool) -> Void
    func _didReceiveMessagePlayedReceiptForMessageID(_: Any, date: Any, attempts: CLongLong, completionBlock: Any) -> Void
    func _didReceiveMessageReadForMessageID(_: Any, date: Any, attempts: CLongLong, useMessageSuppression: Bool) -> Void
    func _didReceiveMessageReadReceiptForMessageID(_: Any, date: Any, attempts: CLongLong, completionBlock: Any) -> Void
    func _didReceiveMessageSavedForMessageID(_: Any, ofType: CLongLong, forChat: Any, fromMe: Bool, attempts: CLongLong, useMessageSuppression: Bool, completionBlock: Any) -> Void
    func _doLoginIgnoringProxy(_: Bool) -> Void
    func _doLoginIgnoringProxy(_: Bool, withAccount: Any) -> Void
    func _endMessageSuppressionForChatGUID(_: Any) -> Void
    func _expireStateTimerFired(_: Any) -> Void
    func _handleExpireStateDictionary(_: Any) -> Void
    func _handleFirewallUserNotificationDidFinish(_: Any) -> Void
    func _handleRoutingWithDictionary(_: Any) -> Void
    func _handleWatchdogWithDictionary(_: Any) -> Void
    func _hasSuppressedMessageID(_: Any, chatGUID: Any) -> Bool
    func _login_checkUsernameAndPasswordWithAccount(_: Any) -> Void
    func _login_serverSettingsReadyWithAccount(_: Any) -> Void
    func _login_usernameAndPasswordReadyWithAccount(_: Any) -> Void
    func _managedPrefsNotification(_: Any) -> Void
    func _mapRoomChatToGroupChat(_: Any, style: CUnsignedChar) -> Void
    func _markChatAsDowngraded(_: Any) -> Void
    func _networkChanged(_: Any) -> Void
    func _newHashForChat(_: Any, style: CUnsignedChar) -> Any
    func _processConnectionMonitorUpdate(_: Any) -> Void
    func _processPotentialNetworkChange(_: Any) -> Void
    func _reconnectIfNecessary(_: Any) -> Void
    func _reconnectIfNecessaryWithAccount(_: Any) -> Void
    func _routingTimerFired(_: Any) -> Void
    func _setAutoReconnectTimer(_: Any) -> Void
    func _setPendingConnectionMonitorUpdate(_: Any) -> Void
    func _setSuppressedMessage(_: Any, inChatWithGUID: Any) -> Void
    func _storageTimerFired(_: Any) -> Void
    func _storeMessage(_: Any, chatIdentifier: Any, localChat: Any, style: CUnsignedChar, account: Any) -> Void
    func _suppresionTimerFired(_: Any) -> Void
    func _transcodeController(_: Any) -> Any
    func _updateConnectionMonitorFromAccountDefaultsIgnoringProxy(_: Bool) -> Void
    func _updateConnectionMonitorWithRemoteHost(_: Any) -> Void
    func _updateExpireStateForMessageGUID(_: Any) -> Void
    func _updateExpireStateTimerWithInterval(_: Double) -> Void
    func _updateInputMessage(_: Any, forExistingMessage: Any) -> Void
    func _updateRoutingForMessageGUID(_: Any, chatGUID: Any, error: CUnsignedInt, account: Any) -> Void
    func _updateRoutingTimerWithInterval(_: Double) -> Void
    func _updateStorageTimerWithInterval(_: Double) -> Void
    func _updateWatchdogForMessageGUID(_: Any) -> Void
    func _updateWatchdogTimerWithInterval(_: Double) -> Void
    func _watchdogTimerFired(_: Any) -> Void
    func _wentOfflineWithAccount(_: Any) -> Void
    func acceptSubscriptionRequest(_: Bool, from: Any) -> Void
    func account(_: Any) -> Any
    func accountDefaults(_: Any) -> Any
    func accountDefaultsChanged(_: Any) -> Void
    func accountID(_: Any) -> Any
    func accountNeedsLogin(_: Bool) -> Bool
    func accountNeedsPassword(_: Bool) -> Bool
    func accountShouldBeAlwaysLoggedIn(_: Bool) -> Bool
    func accounts(_: Any) -> Any
    func addAccount(_: Any) -> Void
    func addAliases(_: Any, account: Any) -> Void
    func allBuddies(_: Any) -> Any
    func allowList(_: Any) -> Any
    func allowedAsChild(_: Bool) -> Bool
    func authenticateAccount(_: Any) -> Void
    func autoLogin(_: Any) -> Void
    func autoReconnect(_: Any) -> Void
    func autoReconnectWithAccount(_: Any) -> Void
    func autoReplier(_: Any, generatedAutoReplyText: Any, forChat: Any) -> Void
    func autoReplier(_: Any, receivedUrgentRequestForMessages: Any) -> Void
    func beginBuddyChanges(_: Any) -> Void
    func blockIdleStatus(_: Bool) -> Bool
    func blockList(_: Any) -> Any
    func blockingMode(_: CUnsignedInt) -> CUnsignedInt
    func broadcaster(_: Any) -> Any
    func broadcasterForACConferenceListeners(_: Any) -> Any
    func broadcasterForAVConferenceListeners(_: Any) -> Any
    func broadcasterForChatListeners(_: Any) -> Any
    func broadcasterForChatObserverListeners(_: Any) -> Any
    func broadcasterForListenersWithCapabilities(_: CUnsignedInt) -> Any
    func broadcasterForVCConferenceListeners(_: Any) -> Any
    func buddyPictures(_: Any) -> Any
    func buddyProperties(_: Any) -> Any
    func canMakeExpireStateChecks(_: Bool) -> Bool
    func cancelVCRequestWithPerson(_: Any, properties: Any, conference: Any) -> Void
    func canonicalFormOfChatRoom(_: Any) -> Any
    func canonicalFormOfID(_: Any) -> Any
    func canonicalizeChatIdentifier(_: Any, style: CUnsignedChar) -> Void
    func capabilities(_: CUnsignedLongLong) -> CUnsignedLongLong
    func changeGroup(_: Any, changes: Any) -> Void
    func changeGroups(_: Any) -> Void
    func changeLocalProperty(_: Any, ofBuddy: Any, to: Any) -> Void
    func changeMyStatus(_: Any, changedKeys: Any) -> Void
    func changeProperty(_: Any, ofBuddy: Any, to: Any) -> Void
    func chatForChatIdentifier(_: Any, style: CUnsignedChar) -> Any
    func chatForChatIdentifier(_: Any, style: CUnsignedChar, account: Any) -> Any
    func chatRoomForGroupChatIdentifier(_: Any) -> Any
    func clearLocalProperties(_: Any) -> Void
    func clearPropertiesOfBuddy(_: Any) -> Void
    func closeSessionChat(_: Any, style: CUnsignedChar) -> Void
    func closeSessionChatID(_: Any, identifier: Any, style: CUnsignedChar) -> Void
    func connectionMonitorDidUpdate(_: Any) -> Void
    func dealloc(_: Any) -> Void
    func declineInvitationToChat(_: Any, style: CUnsignedChar) -> Void
    func declineInvitationToChatID(_: Any, identifier: Any, style: CUnsignedChar) -> Void
    func decrementPendingReadReceiptFromStorageCount(_: Any) -> Void
    func defaultChatSuffix(_: Any) -> Any
    func didChangeMemberStatus(_: Int, forHandle: Any, forChat: Any, style: CUnsignedChar) -> Void
    func didChangeMemberStatus(_: Int, forHandle: Any, fromHandle: Any, unformattedNumber: Any, countryCode: Any, forChat: Any, style: CUnsignedChar) -> Void
    func didChangeMemberStatus(_: Int, forHandle: Any, fromHandle: Any, unformattedNumber: Any, countryCode: Any, forChat: Any, style: CUnsignedChar, account: Any) -> Void
    //func didChangeMemberStatus(_: Int, forHandle: Any, fromHandle: Any, unformattedNumber: Any, countryCode: Any, forChat: Any, style: CUnsignedChar, account: Any) -> Void
    func didChangeMemberStatus(_: Int, forHandle: Any, unformattedNumber: Any, countryCode: Any, forChat: Any, style: CUnsignedChar) -> Void
    func didJoinChat(_: Any, style: CUnsignedChar) -> Void
    func didJoinChat(_: Any, style: CUnsignedChar, displayName: Any, handleInfo: Any) -> Void
    //func didJoinChat(_: Any, style: CUnsignedChar, displayName: Any, handleInfo: Any) -> Void
    func didJoinChat(_: Any, style: CUnsignedChar, displayName: Any, handleInfo: Any, spamExtensionName: Any) -> Void
    func didJoinChat(_: Any, style: CUnsignedChar, displayName: Any, lastAddressedHandle: Any) -> Void
    func didJoinChat(_: Any, style: CUnsignedChar, displayName: Any, lastAddressedHandle: Any, handleInfo: Any) -> Void
    func didJoinChat(_: Any, style: CUnsignedChar, handleInfo: Any) -> Void
    //func didJoinChat(_: Any, style: CUnsignedChar, handleInfo: Any) -> Void
    func didLeaveChat(_: Any, style: CUnsignedChar) -> Void
    func didLeaveChat(_: Any, style: CUnsignedChar, account: Any) -> Void
    func didReceiveBalloonPayload(_: Any, forChat: Any, style: CUnsignedChar, messageGUID: Any) -> Void
    func didReceiveDisplayNameChange(_: Any, fromID: Any, toIdentifier: Any, forChat: Any, style: CUnsignedChar, account: Any) -> Void
    func didReceiveError(_: CUnsignedInt, forMessageID: Any) -> Void
    func didReceiveError(_: CUnsignedInt, forMessageID: Any, account: Any) -> Void
    func didReceiveErrorMessage(_: Any, forChat: Any, style: CUnsignedChar) -> Void
    func didReceiveInvitation(_: Any, forChat: Any, style: CUnsignedChar) -> Void
    func didReceiveMessage(_: Any, forChat: Any, style: CUnsignedChar) -> Void
    func didReceiveMessage(_: Any, forChat: Any, style: CUnsignedChar, account: Any) -> Void
    func didReceiveMessageDeliveryReceiptForMessageID(_: Any, date: Any) -> Bool
    func didReceiveMessageDeliveryReceiptForMessageID(_: Any, date: Any, account: Any) -> Bool
    func didReceiveMessagePlayedForMessageID(_: Any, date: Any, completionBlock: Any) -> Void
    func didReceiveMessagePlayedForMessageID(_: Any, date: Any, useMessageSuppression: Bool, completionBlock: Any) -> Void
    func didReceiveMessagePlayedReceiptForMessageID(_: Any, date: Any, completionBlock: Any) -> Void
    func didReceiveMessageReadForMessageID(_: Any, date: Any, completionBlock: Any) -> Void
    func didReceiveMessageReadForMessageID(_: Any, date: Any, useMessageSuppression: Bool, completionBlock: Any) -> Void
    func didReceiveMessageReadReceiptForMessageID(_: Any, date: Any, completionBlock: Any) -> Void
    func didReceiveMessageSavedForMessageID(_: Any, ofType: CLongLong, forChat: Any, fromMe: Bool, completionBlock: Any) -> Void
    func didReceiveMessageSavedForMessageID(_: Any, ofType: CLongLong, forChat: Any, fromMe: Bool, useMessageSuppression: Bool, completionBlock: Any) -> Void
    func didReceiveMessages(_: Any, forChat: Any, style: CUnsignedChar, account: Any) -> Void
    func didReceiveReplaceMessageID(_: Int, forChat: Any, style: CUnsignedChar) -> Void
    func didSendBalloonPayload(_: Any, forChat: Any, style: CUnsignedChar, messageGUID: Any, completionBlock: Any) -> Void
    func didSendMessage(_: Any, forChat: Any, style: CUnsignedChar) -> Void
    func didSendMessage(_: Any, forChat: Any, style: CUnsignedChar, account: Any) -> Void
    func didSendMessage(_: Any, forChat: Any, style: CUnsignedChar, account: Any, itemIsComingFromStorage: Bool) -> Void
    func didSendMessage(_: Any, forChat: Any, style: CUnsignedChar, forceDate: Any) -> Void
    func didSendMessagePlayedReceiptForMessageID(_: Any) -> Void
    func didSendMessagePlayedReceiptForMessageID(_: Any, account: Any) -> Void
    func didSendMessageReadReceiptForMessageID(_: Any) -> Void
    func didSendMessageReadReceiptForMessageID(_: Any, account: Any) -> Void
    func didSendMessageSavedReceiptForMessageID(_: Any) -> Void
    func didSendMessageSavedReceiptForMessageID(_: Any, account: Any) -> Void
    func didUpdateChatStatus(_: Int, chat: Any, style: CUnsignedChar) -> Void
    func didUpdateChatStatus(_: Int, chat: Any, style: CUnsignedChar, account: Any) -> Void
    func didUpdateChatStatus(_: Int, chat: Any, style: CUnsignedChar, displayName: Any, handleInfo: Any) -> Void
    //func didUpdateChatStatus(_: Int, chat: Any, style: CUnsignedChar, displayName: Any, handleInfo: Any) -> Void
    func didUpdateChatStatus(_: Int, chat: Any, style: CUnsignedChar, displayName: Any, handleInfo: Any, isSpam: Bool) -> Void
    func didUpdateChatStatus(_: Int, chat: Any, style: CUnsignedChar, displayName: Any, lastAddressedHandle: Any) -> Void
    func didUpdateChatStatus(_: Int, chat: Any, style: CUnsignedChar, displayName: Any, lastAddressedHandle: Any, handleInfo: Any) -> Void
    //func didUpdateChatStatus(_: Int, chat: Any, style: CUnsignedChar, displayName: Any, lastAddressedHandle: Any, handleInfo: Any) -> Void
    func didUpdateChatStatus(_: Int, chat: Any, style: CUnsignedChar, displayName: Any, lastAddressedHandle: Any, handleInfo: Any, isSpam: Bool) -> Void
    func didUpdateChatStatus(_: Int, chat: Any, style: CUnsignedChar, handleInfo: Any) -> Void
    func disallowReconnection(_: Any) -> Void
    func displayName(_: Any) -> Any
    func eagerUploadCancel(_: Any) -> Void
    func eagerUploadTransfer(_: Any) -> Void
    func endBuddyChanges(_: Any) -> Void
    func endMessageSuppression(_: Any) -> Void
    func enqueReplayMessageCallback(_: Any) -> Void
    func equalID(_: Any, andID: Any) -> Bool
    func groupChatIdentifierForChatRoom(_: Any) -> Any
    func groups(_: Any) -> Any
    func hasCapability(_: CUnsignedLongLong) -> Bool
    func holdBuddyUpdates(_: Any) -> Void
    func incrementPendingReadReceiptFromStorageCount(_: Any) -> Void
    func initWithAccount(_: Any, service: Any) -> Any
    func invitePerson(_: Any, withMessage: Any, toChat: Any, style: CUnsignedChar) -> Void
    func invitePersonInfo(_: Any, withMessage: Any, toChat: Any, style: CUnsignedChar) -> Void
    func invitePersonInfo(_: Any, withMessage: Any, toChatID: Any, identifier: Any, style: CUnsignedChar) -> Void
    func invitePersonInfoToiMessageChat(_: Any, withMessage: Any, toChat: Any, style: CUnsignedChar) -> Void
    func invitePersonInfoToiMessageChat(_: Any, withMessage: Any, toChatID: Any, identifier: Any, style: CUnsignedChar) -> Void
    func isActive(_: Bool) -> Bool
    func isAwaitingStorageTimer(_: Bool) -> Bool
    func isChatRegistered(_: Any, style: CUnsignedChar) -> Bool
    func joinChat(_: Any, handleInfo: Any, style: CUnsignedChar, groupID: Any) -> Void
    func joinChat(_: Any, handleInfo: Any, style: CUnsignedChar, groupID: Any, lastAddressedSIMID: Any) -> Void
    func joinChat(_: Any, style: CUnsignedChar, groupID: Any) -> Void
    func joinChat(_: Any, style: CUnsignedChar, joinProperties: Any) -> Void
    func joinChatID(_: Any, handleInfo: Any, identifier: Any, style: CUnsignedChar, groupID: Any, lastAddressedSIMID: Any) -> Void
    func leaveAllChats(_: Any) -> Void
    func leaveChat(_: Any, style: CUnsignedChar) -> Void
    func leaveChatID(_: Any, identifier: Any, style: CUnsignedChar) -> Void
    func leaveiMessageChat(_: Any, style: CUnsignedChar) -> Void
    func leaveiMessageChatID(_: Any, identifier: Any, style: CUnsignedChar) -> Void
    func localPropertiesOfBuddy(_: Any) -> Any
    func localProperty(_: Any, ofBuddy: Any) -> Any
    func login(_: Any) -> Void
    func loginID(_: Any) -> Any
    func loginIDForAccount(_: Any) -> Any
    func loginServiceSessionWithAccount(_: Any) -> Void
    func loginWithAccount(_: Any) -> Void
    func logout(_: Any) -> Void
    func logoutServiceSessionWithAccount(_: Any) -> Void
    func logoutWithAccount(_: Any) -> Void
    func markBuddiesAsChanged(_: Any) -> Void
    func networkConditionsAllowLogin(_: Bool) -> Bool
    func noteBadPassword(_: Any) -> Void
    func noteItemFromStorage(_: Any) -> Void
    func noteLastItemFromStorage(_: Any) -> Void
    func noteLastItemProcessed(_: Any) -> Void
    func noteMessagesMarkedAsReadForChatWithGUID(_: Any) -> Void
    func noteSuppressedMessageUpdate(_: Any) -> Void
    func notifyDidSendMessageID(_: Any) -> Void
    func notifyDidSendMessageID(_: Any, account: Any, shouldNotify: Bool) -> Void
    func notifyDidSendMessageID(_: Any, shouldNotify: Bool) -> Void
    func otcUtilities(_: Any) -> Any
    func overrideNetworkAvailability(_: Bool) -> Bool
    func password(_: Any) -> Any
    func passwordUpdatedWithAccount(_: Any) -> Void
    func pendingReadReceiptFromStorageCount(_: CUnsignedLongLong) -> CUnsignedLongLong
    func pictureKeyForBuddy(_: Any) -> Any
    func pictureOfBuddy(_: Any) -> Any
    func processMessageForSending(_: Any, toChat: Any, style: CUnsignedChar, allowWatchdog: Bool, completionBlock: Any) -> Void
    func processMessageForSending(_: Any, toChat: Any, style: CUnsignedChar, allowWatchdog: Bool) -> Void
    func property(_: Any, ofBuddy: Any) -> Any
    func proxyAccount(_: Any) -> Any
    func proxyHost(_: Any) -> Any
    func proxyPassword(_: Any) -> Any
    func proxyPort(_: CUnsignedShort) -> CUnsignedShort
    func proxyType(_: CLongLong) -> CLongLong
    func refreshServiceCapabilities(_: Any) -> Void
    func registerAccount(_: Any) -> Void
    func registerChat(_: Any, groupID: Any, style: CUnsignedChar) -> Void
    func registerChat(_: Any, style: CUnsignedChar) -> Void
    func registerChat(_: Any, style: CUnsignedChar, displayName: Any, handleInfo: Any) -> Void
    //func registerChat(_: Any, style: CUnsignedChar, displayName: Any, handleInfo: Any) -> Void
    func registerChat(_: Any, style: CUnsignedChar, displayName: Any, lastAddressedHandle: Any, account: Any) -> Void
    func registerChat(_: Any, style: CUnsignedChar, displayName: Any, lastAddressedHandle: Any, handleInfo: Any) -> Void
    func registerChat(_: Any, style: CUnsignedChar, handleInfo: Any) -> Void
    func registrationAlertInfo(_: Any) -> Any
    func registrationError(_: Int) -> Int
    func registrationStatus(_: Int) -> Int
    func relay(_: Any, sendCancel: Any, toPerson: Any) -> Void
    func relay(_: Any, sendInitateRequest: Any, toPerson: Any) -> Void
    func relay(_: Any, sendUpdate: Any, toPerson: Any) -> Void
    func removeAccount(_: Any) -> Void
    func removeAliases(_: Any, account: Any) -> Void
    func removeChat(_: Any, style: CUnsignedChar) -> Void
    func removeChatID(_: Any, identifier: Any, style: CUnsignedChar) -> Void
    func removePersonInfo(_: Any, chatID: Any, identifier: Any, style: CUnsignedChar) -> Void
    func removePersonInfoFromiMessageChat(_: Any, chatID: Any, identifier: Any, style: CUnsignedChar) -> Void
    func renameGroup(_: Any, to: Any) -> Void
    func replayMessage(_: Any) -> Void
    func requestGroups(_: Any) -> Void
    func requestProperty(_: Any, ofPerson: Any) -> Void
    func requestSubscriptionTo(_: Any) -> Void
    func requestVCWithPerson(_: Any, properties: Any, conference: Any) -> Void
    func respondToVCInvitationWithPerson(_: Any, properties: Any, conference: Any) -> Void
    func resumeBuddyUpdates(_: Any) -> Void
    func scheduleTransactionLogTask(_: Any) -> Void
    func sendAVMessageToPerson(_: Any, sessionID: CUnsignedInt, type: CUnsignedInt, userInfo: Any) -> Void
    func sendCommand(_: Any, withProperties: Any, toPerson: Any) -> Void
    func sendCommand(_: Any, withProperties: Any, toPerson: Any, toChatID: Any, identifier: Any, style: CUnsignedChar) -> Void
    func sendCounterProposalToPerson(_: Any, properties: Any, conference: Any) -> Void
    func sendDeleteCommand(_: Any, forChatGUID: Any) -> Void
    func sendFileTransfer(_: Any, toPerson: Any) -> Void
    func sendLocationSharingInfo(_: Any, toID: Any, completionBlock: Any) -> Void
    func sendLogDumpMessageAtFilePath(_: Any, toRecipient: Any, shouldDeleteFile: Bool) -> Void
    func sendMessage(_: Any, toChat: Any, style: CUnsignedChar) -> Void
    //func sendMessage(_: Any, toChat: Any, style: CUnsignedChar, account: Any) -> Void
    //func sendMessage(_: Any, toChatID: Any, identifier: Any, style: CUnsignedChar) -> Void
    func sendPlayedReceiptForMessage(_: Any, toChatID: Any, identifier: Any, style: CUnsignedChar) -> Void
    func sendReadReceiptForMessage(_: Any, toChatID: Any, identifier: Any, style: CUnsignedChar) -> Void
    func sendSavedReceiptForMessage(_: Any, toChatID: Any, identifier: Any, style: CUnsignedChar) -> Void
    func sendSavedReceiptForMessage(_: Any, toChatID: Any, identifier: Any, style: CUnsignedChar, account: Any) -> Void
    func sendVCUpdate(_: Any, toPerson: Any, conference: Any) -> Void
    func server(_: Any) -> Any
    func serverHost(_: Any) -> Any
    func serverPort(_: CUnsignedShort) -> CUnsignedShort
    func service(_: Any) -> Any
    func serviceSessionDidLoginWithAccount(_: Any) -> Void
    func serviceSessionDidLogoutWithAccount(_: Any) -> Void
    func serviceSessionDidLogoutWithMessage(_: Any, reason: Int, properties: Any, account: Any) -> Void
    func sessionDidBecomeActive(_: Any) -> Void
    func sessionWillBecomeInactiveWithAccount(_: Any) -> Void
    func setAllowList(_: Any) -> Void
    func setBlockIdleStatus(_: Bool) -> Void
    func setBlockList(_: Any) -> Void
    func setBlockingMode(_: CUnsignedInt) -> Void
    func setIdleTime(_: CUnsignedInt) -> Void
    func setPendingReadReceiptFromStorageCount(_: CUnsignedLongLong) -> Void
    func setProperties(_: Any, ofParticipant: Any, inChat: Any, style: CUnsignedChar) -> Void
    func setProperties(_: Any, ofParticipant: Any, inChatID: Any, identifier: Any, style: CUnsignedChar) -> Void
    func setRegistrationStatus(_: Int, error: Int, alertInfo: Any) -> Void
    func setValue(_: Any, ofProperty: Any, ofPerson: Any) -> Void
    func shouldImitateGroupChatUsingChatRooms(_: Bool) -> Bool
    func startWatchingBuddy(_: Any) -> Void
    func stopWatchingBuddy(_: Any) -> Void
    func systemDidUnlock(_: Any) -> Void
    func systemProxySettingsFetcher(_: Any, retrievedAccount: Any, password: Any) -> Void
    func systemProxySettingsFetcher(_: Any, retrievedHost: Any, port: CUnsignedShort, protocol: CLongLong) -> Void
    func testOverrideTextValidationDidFail(_: Bool) -> Bool
    func unregisterAccount(_: Any) -> Void
    func unregisterChat(_: Any, style: CUnsignedChar) -> Void
    func unvalidateAliases(_: Any, account: Any) -> Void
    func updateAuthorizationCredentials(_: Any, token: Any, account: Any) -> Void
    func updateConnectionMonitorWithLocalSocketAddress(_: Any, remoteSocketAddress: Any) -> Void
    func updateDisplayName(_: Any, fromDisplayName: Any, forChatID: Any, identifier: Any, style: CUnsignedChar) -> Void
    func useChatRoom(_: Any, forGroupChatIdentifier: Any) -> Void
    func useSSL(_: Bool) -> Bool
    func userNotificationDidFinish(_: Any) -> Void
    func validateAliases(_: Any, account: Any) -> Void
    func validateProfileWithAccount(_: Any) -> Void
    //func validityOfChatRoomName(_: Any) -> struct _FZChatRoomValidity { Int x1; CUnsignedShort x2; }
    func warnIfPortBlocked(_: Int, forAction: Any) -> Bool
}
