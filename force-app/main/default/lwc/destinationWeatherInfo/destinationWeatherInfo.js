import { api, LightningElement, track, wire } from 'lwc';
import getCurrentWeather from '@salesforce/apex/WeatherInfoController.getCurrentWeather';
import getWeatherForecast from '@salesforce/apex/WeatherInfoController.getWeatherForecast';
import getDestinations from '@salesforce/apex/WeatherInfoController.getDestinations';

export default class WeatherComponent extends LightningElement {
    @api apiKey;
    @track destinations = [];
    @track selectedDestination = '';
    @track selectedCountry = '';
    @track currentWeather = {};
    @track dailyForecast = [];
    @track isLoading = false;
    @track error;
    
    @track currentWeatherIcon = 'utility:world';
    @track forecastIcons = [];

    countryFlagStyles = {
        'AR': 'argentina-flag',
        'BR': 'brazil-flag',
        'CL': 'chile-flag',
        'CO': 'colombia-flag',
        'EC': 'ecuador-flag',
        'PE': 'peru-flag',
        'UY': 'uruguay-flag',
        'VE': 'venezuela-flag',
        'BO': 'bolivia-flag',
        'PY': 'paraguay-flag'
    };
    
    @wire(getDestinations)
    wiredDestinations({ error, data }) {
        if (data) {
            this.destinations = data;
        } else if (error) {
            this.error = error;
        }
    }
    
    async handleCountrySelection(event) {
        this.isLoading = true;
        this.selectedDestination = event.currentTarget.dataset.name;
        this.selectedCountry = event.currentTarget.dataset.country;
        this.error = undefined;
        
        try {
            const current = await getCurrentWeather({ destination: this.selectedDestination });
            const forecast = await getWeatherForecast({ destination: this.selectedDestination });
            
            this.updateWeatherData(current, forecast);
            
        } catch (error) {
            this.error = error.body?.message || error.message;
        } finally {
            this.isLoading = false;
        }
    }
    
    updateWeatherData(current, forecast) {
        const temp = parseInt(current?.temperature) || 20;
    
        const feelsLikeOffset = Math.floor(Math.random() * 4) - 1;
        const feelsLike = temp + feelsLikeOffset;
        
        const windSpeed = Math.floor(Math.random() * 26) + 5;
        
        const pressure = Math.floor(Math.random() * 61) + 980;
    
        this.currentWeather = {
            temp: current?.temperature || '--',
            description: current?.description || 'No data',
            humidity: current?.humidity || '--',
            feelsLike: feelsLike.toString(),
            windSpeed: windSpeed.toString(),
            pressure: pressure.toString(),
            location: current?.location || this.selectedDestination
        };
            
        this.currentWeatherIcon = this.getWeatherIcon(current?.description);
        
        this.dailyForecast = forecast?.map(day => ({
            day: day.day,
            temp: {
                max: day.temperature,
                min: (parseInt(day.temperature) - 2).toString()
            },
            description: day.description,
            icon: this.getWeatherIcon(day.description),
        })) || [];
        
        this.forecastIcons = forecast?.map(day => this.getWeatherIcon(day.description)) || [];
    }

    getCountryCardClass(dest) {
        let classes = 'country-card slds-card';
        if (this.selectedDestination === dest.name) {
            classes += ' selected';
        }
        if (dest.flagClass) {
            classes += ' ' + dest.flagClass;
        }
        return classes;
    }

    get decoratedDestinations() {
        return this.destinations.map(dest => ({
            ...dest,
            cardClass: this.buildCountryCardClass(dest)
        }));
    }

    buildCountryCardClass(dest) {
        let classes = 'country-card slds-card';
        if (this.selectedDestination === dest.name) {
            classes += ' selected';
        }
        if (this.countryFlagStyles[dest.country]) {
            classes += ' ' + this.countryFlagStyles[dest.country];
        }
        return classes;
    }
    
    getWeatherIcon(description) {
        const iconMap = {
            'Sunny': 'utility:spinner',
            'Partly Cloudy': 'utility:world',
            'Cloudy': 'utility:salesforce1',
            'Rainy': 'utility:water',
            'Thunderstorms': 'utility:connected_apps',
            'Snowy': 'utility:frozen'
        };
        return iconMap[description] || 'utility:world';
    }
    
    getRegionTheme(region) {
        const themes = {
            'South America': 'success',
            'North America': 'warning',
            'Europe': 'info',
            'Asia': 'error',
            'Africa': 'offline'
        };
        return themes[region] || 'default';
    }
}