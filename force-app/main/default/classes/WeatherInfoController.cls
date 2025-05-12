/**
 * @author Christian Chilavert
 * @description Controller class for retrieving weather information for tourist destinations
 */
@RestResource(urlMapping='/WeatherService/*')
global with sharing class WeatherInfoController {

    // Base URL for weather API endpoints
    private static final String BASE_URL = 'https://oktana-e0-dev-ed.develop.my.site.com/tech/services/apexrest/WeatherService';

    // Map of available destinations with their country codes
    private static Map<String, Map<String, String>> availableDestinations = new Map<String, Map<String, String>>{
        'Buenos Aires' => new Map<String, String>{ 'country' => 'AR' },
        'Rio de Janeiro' => new Map<String, String>{ 'country' => 'BR' },
        'Santiago' => new Map<String, String>{ 'country' => 'CL' },
        'Bogotá' => new Map<String, String>{ 'country' => 'CO' },
        'Quito' => new Map<String, String>{ 'country' => 'EC' },
        'Lima' => new Map<String, String>{ 'country' => 'PE' },
        'Montevideo' => new Map<String, String>{ 'country' => 'UY' },
        'Caracas' => new Map<String, String>{ 'country' => 'VE' },
        'La Paz' => new Map<String, String>{ 'country' => 'BO' },
        'Asunción' => new Map<String, String>{ 'country' => 'PY' }
    };

    /**
     * @description Retrieves current weather data for a specific destination
     * @param destination The city name to get weather for
     * @return CurrentWeather Object containing current weather data
     * @throws AuraHandledException If API call fails or data processing error occurs
     */
    @AuraEnabled
    public static CurrentWeather getCurrentWeather(String destination) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(BASE_URL + '/current/' + EncodingUtil.urlEncode(destination, 'UTF-8'));
        req.setMethod('GET');
        req.setTimeout(120000);
        
        HttpResponse res = makeCallout(req);
        
        if (res.getStatusCode() == 200) {
            try {
                CurrentWeather result = (CurrentWeather) JSON.deserialize(res.getBody(), CurrentWeather.class);
                return result;
            } catch(Exception e) {
                throw new AuraHandledException('Error processing weather data: '+e.getMessage());
            }
        } else {
            handleError(res);
            throw new AuraHandledException('API Error: '+res.getStatusCode()+' - '+res.getBody());
        }
    }
    
    /**
     * @description Retrieves weather forecast for a specific destination
     * @param destination The city name to get forecast for
     * @return List<DailyForecast> List of forecast objects for upcoming days
     * @throws AuraHandledException If API call fails
     */
    @AuraEnabled(cacheable=true)
    public static List<DailyForecast> getWeatherForecast(String destination) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(BASE_URL + '/forecast/' + EncodingUtil.urlEncode(destination, 'UTF-8'));
        req.setMethod('GET');
        
        HttpResponse res = makeCallout(req);
        
        if (res.getStatusCode() == 200) {
            return (List<DailyForecast>) JSON.deserialize(res.getBody(), List<DailyForecast>.class);
        } else {
            handleError(res);
            return null;
        }
    }
    
    /**
     * @description Makes HTTP callout to external service
     * @param req Configured HTTPRequest object
     * @return HttpResponse Response from the callout
     * @throws AuraHandledException If callout fails
     */
    global static HttpResponse makeCallout(HttpRequest req) {
        Http http = new Http();
        try {
            return http.send(req);
        } catch (Exception e) {
            throw new AuraHandledException('Error making callout: ' + e.getMessage());
        }
    }
    
    /**
     * @description Handles API error responses and formats error messages
     * @param res HTTPResponse object containing error details
     * @throws AuraHandledException Always throws exception with formatted error message
     */
    global static void handleError(HttpResponse res) {
        String errorMessage;
        if (res.getStatusCode() == 500) {
            errorMessage = 'API Error: ' + res.getBody();
        } else {
            errorMessage = 'Unexpected HTTP response: ' + res.getStatusCode() + ' - ' + res.getBody();
        }
        throw new AuraHandledException(errorMessage);
    }

    /**
     * @description Retrieves list of available travel destinations
     * @return List<Destination> List of destination objects
     */
    @AuraEnabled(cacheable=true)
    public static List<Destination> getDestinations() {
        List<Destination> destinations = new List<Destination>();
        
        for(String city : availableDestinations.keySet()) {
            Map<String, String> data = availableDestinations.get(city);
            destinations.add(new Destination(city, data.get('country')));
        }
        
        return destinations;
    }

    /**
     * @description Inner class representing a travel destination
     */
    public class Destination {
        @AuraEnabled public String name;
        @AuraEnabled public String country;
        
        public Destination(String name, String country) {
            this.name = name;
            this.country = country;
        }
    }

    /**
     * @description Inner class representing current weather data
     */
    public class CurrentWeather {
        @AuraEnabled public String location {get; set;}
        @AuraEnabled public String temperature {get; set;}
        @AuraEnabled public String description {get; set;}
        @AuraEnabled public String humidity {get; set;}
        
        public CurrentWeather() {}
    }
    
    /**
     * @description Inner class representing daily forecast data
     */
    public class DailyForecast {
        @AuraEnabled public String day;
        @AuraEnabled public String temperature;
        @AuraEnabled public String description;
    }
    
    /**
     * @description Custom exception class for weather service errors
     */
    public class WeatherServiceException extends Exception {}
}