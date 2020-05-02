import 'dart:async';
import 'package:flutter/material.dart';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import 'package:audioservicetestingapp/constants.dart';

void main() {
  runApp(RadioTest());
}

class RadioTest extends StatefulWidget {
  @override
  _RadioTestState createState() => _RadioTestState();
}

class _RadioTestState extends State<RadioTest> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AudioService Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AudioServiceWidget(child: MainScreen()),
    );
  }
}

class MainScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AudioService Test")),
      body: Center(
        child: StreamBuilder<PlaybackState>(
          stream: AudioService.playbackStateStream,
          builder: (context, snapshot) {
            final state =
                snapshot.data?.basicState ?? BasicPlaybackState.stopped;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state == BasicPlaybackState.playing)
                  RaisedButton(child: Text("Pause"), onPressed: pause)
                else
                  RaisedButton(child: Text("Start Play"), onPressed: play),
                if (state != BasicPlaybackState.stopped)
                  RaisedButton(child: Text("Stop"), onPressed: stop),
              ],
            );
          },
        ),
      ),
    );
  }

  play() async {
    if (await AudioService.running) {
      print("Start Play");
      AudioService.play();
    } else {
      print("Start Audio Service");
      AudioService.start(backgroundTaskEntrypoint: _backgroundTaskEntrypoint);
    }
  }

  pause() => AudioService.pause();

  stop() => AudioService.stop();

  start() =>
      AudioService.start(backgroundTaskEntrypoint: _backgroundTaskEntrypoint);

  //stop() => AudioService.stop();

  _backgroundTaskEntrypoint() {
    AudioServiceBackground.run(() => AudioPlayerTask());
  }
}

class AudioPlayerTask extends BackgroundAudioTask {
  final _audioPlayer = AudioPlayer();
  final _completer = Completer();


  @override
  Future<void> onStart() async {
    // Broadcast that we're playing, and what controls are available.
    AudioServiceBackground.setState(
        controls: [pauseControl, stopControl],
        basicState: BasicPlaybackState.playing);
    await _audioPlayer
        .setUrl("http://canada1.reliastream.com:8052/live?type=.mp3");
    _audioPlayer.play();
    await _completer.future;
    // Broadcast that we've stopped.
    AudioServiceBackground.setState(
        controls: [], basicState: BasicPlaybackState.playing);
  }

  @override
  void onPlay() {
    // Broadcast that we're playing, and what controls are available.
    AudioServiceBackground.setState(
        controls: [pauseControl, stopControl],
        basicState: BasicPlaybackState.playing);
    _audioPlayer.play();
  }

  @override
  void onPause() {
    // Broadcast that we're paused, and what controls are available.
    AudioServiceBackground.setState(
        controls: [playControl, stopControl],
        basicState: BasicPlaybackState.playing);
    _audioPlayer.pause();
  }

  @override
  void onStop() {
    _audioPlayer.stop();
    _completer.complete();
  }
}