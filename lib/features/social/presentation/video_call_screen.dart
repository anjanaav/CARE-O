import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/agora_token_service.dart';
import '../../../core/widgets/state_views.dart';

/// Replaces the previous VideoCallScreen: uses the single consolidated
/// AgoraTokenService/AppConfig (instead of two duplicate services pointed
/// at a hardcoded emulator URL), and shows a real error state instead of
/// only printing to the console when the token fetch fails.
class VideoCallScreen extends StatefulWidget {
  final String channelName;

  const VideoCallScreen({super.key, required this.channelName});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  static const _tokenService = AgoraTokenService();

  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isLoading = true;
  bool _hasError = false;
  int? _remoteUid;

  @override
  void initState() {
    super.initState();
    _initializeAgora();
  }

  Future<void> _initializeAgora() async {
    final token = await _tokenService.fetchToken(widget.channelName);
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
        _isLoading = false;
        _hasError = true;
      });
      }
      return;
    }

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(
      const RtcEngineContext(
        appId: AppConfig.agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          if (mounted) setState(() => _isJoined = true);
        },
        onUserJoined: (connection, uid, elapsed) {
          if (mounted) setState(() => _remoteUid = uid);
        },
        onUserOffline: (connection, uid, reason) {
          if (mounted) setState(() => _remoteUid = null);
        },
      ),
    );

    await _engine!.enableVideo();
    await _engine!.startPreview();
    await _engine!.joinChannel(
      token: token,
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );

    if (mounted) setState(() => _isLoading = false);
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _engine?.muteLocalAudioStream(_isMuted);
  }

  void _toggleVideo() {
    setState(() => _isVideoEnabled = !_isVideoEnabled);
    _engine?.muteLocalVideoStream(!_isVideoEnabled);
  }

  void _endCall() async {
    await _engine?.leaveChannel();
    await _engine?.release();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Call')),
      body: _hasError
          ? AppErrorState(
              message: "Couldn't connect to the call. Please try again.",
              onRetry: () {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
                _initializeAgora();
              },
            )
          : (_isLoading || !_isJoined)
              ? const LoadingState(message: 'Joining call...')
              : Stack(
                  children: [
                    _remoteUid != null
                        ? AgoraVideoView(
                            controller: VideoViewController.remote(
                              rtcEngine: _engine!,
                              canvas: VideoCanvas(uid: _remoteUid!),
                              connection: RtcConnection(channelId: widget.channelName),
                            ),
                          )
                        : const Center(child: Text('Waiting for the other person to join...')),
                    Positioned(
                      bottom: 20,
                      right: 20,
                      width: 100,
                      height: 150,
                      child: AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: _engine!,
                          canvas: const VideoCanvas(uid: 0),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 30,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton.filled(
                            onPressed: _toggleMute,
                            icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
                          ),
                          IconButton.filled(
                            onPressed: _toggleVideo,
                            icon: Icon(_isVideoEnabled ? Icons.videocam : Icons.videocam_off),
                          ),
                          IconButton.filled(
                            onPressed: () => _engine?.switchCamera(),
                            icon: const Icon(Icons.switch_camera),
                          ),
                          IconButton.filled(
                            onPressed: _endCall,
                            style: IconButton.styleFrom(backgroundColor: Colors.red),
                            icon: const Icon(Icons.call_end),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
