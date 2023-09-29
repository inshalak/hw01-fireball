
export var gl: WebGL2RenderingContext;
export function setGL(_gl: WebGL2RenderingContext) {
  gl = _gl;
}
declare interface Window {
  onSpotifyWebPlaybackSDKReady: () => void;
}
