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
Speedometer = function (gaugeID) {
	//[State]
	var mph;
	var kph;
		
	//[Initialization]
	this.SetGaugeID(gaugeID);
	this.SetGaugeX(317); this.SetGaugeY(317);
	
	this.SetPosX(135); this.SetPosY(55); this.SetWidth(47); this.SetHeight(145);
	this.LoadCX(0); this.LoadCY(3);

	this.CreateGauge();	
	this.SetMPH(0); //initialize control
};

//Inherit gauge functionality
Speedometer.prototype = new Gauge();

//[Properties]
Speedometer.prototype.SetMPH = function(mph) {
	this.mph = mph;
	
	if( this.mphValidated() ) 
		this.RotateNeedle( this.mph2deg() );
};

Speedometer.prototype.GetMPH = function() {
	return this.mph;
};

Speedometer.prototype.SetKPH = function(kph) {
	this.kph = kph;
	
	if( this.kphValidated() )
		this.RotateNeedle( this.kph2deg() );
};

Speedometer.prototype.GetKPH = function() {
	return this.kph;
};

//[Methods]
//Speed to degree mappings
Speedometer.prototype.mph2deg = function() {
		return ((this.mph - 50) * 2.62) + (((this.mph - 50) * 1.8999) * 0.022900763);
};

Speedometer.prototype.kph2deg = function() {
	return ((this.kph - 120) * 1.12) - (((this.kph - 120) * 1.12) * 0.009);
};

Speedometer.prototype.Accelerate = function() {
	//Setup Timer
	jQuery(this).everyTime(10, function(i) {
		if(i < 300) {
			var v = i*80;
			this.SetMPH(easeInCirc(i, 0, v, 2000));
		}
	}, 0);
	
	/////////// CIRCULAR EASING: sqrt(1-t^2) //////////////
	// circular easing in - accelerating from zero velocity
	// t: current time, b: beginning value, c: change in position, d: duration
	easeInCirc = function (t, b, c, d) {
		return -c * (Math.sqrt(1 - (t/=d)*t) - 1) + b;
	};
};

//Validation
Speedometer.prototype.mphValidated = function() {
	return ((this.mph >= 0) && (this.mph <= 100));
};

Speedometer.prototype.kphValidated = function() {
	return ((this.kph >= 0) && (this.kph <= 240));
};