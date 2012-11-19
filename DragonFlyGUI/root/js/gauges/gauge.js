/**
 * jQuery Dashboard Gauges v0.2.0
 * http://techoctave.com/c7
 *
 * Copyright (c) 2010 by Tian Valdemar Davis
 * 
 * Free for Personal and Educational Use
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * Date: Mon Sep 6 10:00:00 2010 -0500
 */
Gauge = function () {
	//[State]
	var gaugeID; //container e.g. speedometer
	var gaugeX; //gauge width
	var gaugeY; //gauge height
	var gaugeCanvas;
	
	//var needleID; //container e.g. needle
	var src; //needle src
	var needle; //needle object
	var posX; //needle x postion on gauge
	var posY; //needle y position on gauge
	var width; //needle width
	var height; //needle height
	var cX; //needle center rotation x
	var cY; //needle center rotation y
};

//[Properties]
Gauge.prototype.SetGaugeX = function(gaugeX) {
	this.gaugeX = gaugeX;
};

Gauge.prototype.SetGaugeY = function(gaugeY) {
	this.gaugeY = gaugeY;
};

Gauge.prototype.SetGaugeID = function(gaugeID) {
	this.gaugeID = gaugeID;
};

Gauge.prototype.SetNeedleID = function(needleID) {
	this.needleID = needleID;
};

Gauge.prototype.SetPosX = function(posX) {
	this.posX = posX;
};

Gauge.prototype.SetPosY = function(posY) {
	this.posY = posY;
};

Gauge.prototype.SetWidth = function(width) {
	this.width = width;
};

Gauge.prototype.SetHeight = function(height) {
	this.height = height;
};

//[Methods]	
Gauge.prototype.LoadCX = function(offsetX) {
	this.cX = (this.gaugeX/2) + offsetX;
};

Gauge.prototype.LoadCY = function(offsetY) {
	this.cY = (this.gaugeY/2) + offsetY;
};

Gauge.prototype.CreateGauge = function() {
	//this.src = document.getElementById(this.needleID).src;
	this.src = document.getElementById(this.gaugeID).getElementsByTagName('img')[0].src; //needle src
	document.getElementById(this.gaugeID).innerHTML = ""; //clear canvas container
	
	this.gaugeCanvas = Raphael(this.gaugeID, this.gaugeX, this.gaugeY); //create canvas
	this.needle = this.gaugeCanvas.image(this.src, this.posX, this.posY, this.width, this.height); //create needle object
};

Gauge.prototype.RotateNeedle = function(deg) {
	this.needle.rotate(deg, this.cX, this.cY);
};