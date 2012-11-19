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
Fuel = function (gaugeID) {
	//[State]
	var fuel; //percent of total fuel - 0 to 100
	
	//[Properties]
	this.SetFuel = function(fuel) {
		this.fuel = fuel;
		
		if( this.fuelValidated() ) 
			this.RotateNeedle( this.fuel2deg() );
	};
	
	this.GetFuel = function() {
		return this.fuel;
	};
	
	//[Methods]
	//Fuel to degree mappings
	this.fuel2deg = function() {
		return ((this.fuel - 50) * 1.35);
	};
	
	//Validation
	this.fuelValidated = function() {
		return ((this.fuel >= 0) && (this.fuel <= 100));
	};
	
	//[Constructor]
	this.SetGaugeID(gaugeID);
	this.SetGaugeX(195); this.SetGaugeY(195);
	
	this.SetPosX(85); this.SetPosY(23); this.SetWidth(23); this.SetHeight(85);
	this.LoadCX(0); this.LoadCY(-2);

	this.CreateGauge();
	this.SetFuel(0); //initialize control
	
	return true;
};

//Inherit gauge functionality
Fuel.prototype = new Gauge();