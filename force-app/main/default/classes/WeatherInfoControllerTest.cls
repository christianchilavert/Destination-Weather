/**
 * @author Christian Chilavert
 * @description Test class for WeatherInfoController
 * @since 2023-10-15
 */
@IsTest
private class WeatherInfoControllerTest {
    
    /**
     * @description Mock class for simulating HTTP responses with configurable status codes and bodies
     */
    private class WeatherMock implements HttpCalloutMock {
        private Integer statusCode;
        private String body;
        
        /**
         * @description Constructor for WeatherMock
         * @param statusCode HTTP status code to return
         * @param body Response body to return
         */
        public WeatherMock(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }
        
        /**
         * @description Simulates HTTP response based on configured values
         * @param req The HTTP request being made
         * @return HTTPResponse Simulated response
         */
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            return res;
        }
    }

    /**
     * @description Mock class for simulating successful HTTP responses
     */
    private class SuccessMock implements HttpCalloutMock {
        /**
         * @description Simulates successful HTTP responses for different endpoints
         * @param req The HTTP request being made
         * @return HTTPResponse Simulated successful response
         */
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);

            if (req.getEndpoint().contains('/current/')) {
                res.setBody('{"location":"Buenos Aires","temperature":"22°C","description":"Sunny","humidity":"60%"}');
            } else if (req.getEndpoint().contains('/forecast/')) {
                res.setBody('[{"day":"Monday","temperature":"22°C","description":"Sunny"}, {"day":"Tuesday","temperature":"21°C","description":"Cloudy"}]');
            }

            return res;
        }
    }

    /**
     * @description Tests successful retrieval of current weather data
     * @verifies That current weather data is properly returned
     * @verifies That response is correctly deserialized
     */
    @IsTest
    static void testGetCurrentWeather() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        WeatherInfoController.CurrentWeather result = WeatherInfoController.getCurrentWeather('Buenos Aires');
        Test.stopTest();

        // Verify response was processed correctly
        System.assertNotEquals(null, result, 'Response should not be null');
        System.assertEquals('Buenos Aires', result.location, 'Location should match mock data');
        System.assertEquals('22°C', result.temperature, 'Temperature should match mock data');
    }

    /**
     * @description Tests successful retrieval of weather forecast
     * @verifies That forecast data is properly returned
     * @verifies That forecast list contains expected items
     */
    @IsTest
    static void testGetWeatherForecast() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        List<WeatherInfoController.DailyForecast> forecast = WeatherInfoController.getWeatherForecast('Buenos Aires');
        Test.stopTest();

        // Verify forecast data was processed correctly
        System.assertNotEquals(null, forecast, 'Forecast should not be null');
        System.assertEquals(2, forecast.size(), 'Should return 2 forecast days');
        System.assertEquals('Monday', forecast[0].day, 'First day should be Monday');
        System.assertEquals('22°C', forecast[0].temperature, 'Temperature should match mock data');
    }

    /**
     * @description Tests retrieval of available destinations
     * @verifies That all destinations are returned
     * @verifies That destination data is correct
     */
    @IsTest
    static void testGetDestinations() {
        Test.startTest();
        List<WeatherInfoController.Destination> destinations = WeatherInfoController.getDestinations();
        Test.stopTest();

        // Verify destination list
        System.assertEquals(10, destinations.size(), 'Should return 10 destinations');
        
        // Verify specific destination exists
        Boolean found = false;
        for (WeatherInfoController.Destination dest : destinations) {
            if (dest.name == 'Buenos Aires' && dest.country == 'AR') {
                found = true;
                break;
            }
        }
        System.assertEquals(true, found, 'Buenos Aires should be in destinations');
    }
    
    /**
     * @description Tests error handling for 500 server errors
     * @verifies That 500 errors are properly handled
     * @verifies That correct exception is thrown
     */
    @IsTest
    static void testGetCurrentWeather_500Error() {
        Test.setMock(HttpCalloutMock.class, new WeatherMock(500, 'Internal Server Error'));
        
        Test.startTest();
        try {
            WeatherInfoController.CurrentWeather result = WeatherInfoController.getCurrentWeather('Buenos Aires');
            System.assert(false, 'Expected exception was not thrown');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage(), 'Unexpected error message');
        }
        Test.stopTest();
    }
}