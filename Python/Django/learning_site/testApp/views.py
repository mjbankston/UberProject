from django.shortcuts import render
from django.http import HttpResponse
from django.template import loader

# These methods get a HttpRequest object and return an HttpResponse object


def index(request):
    context = {}

    # render(request, url, context) is a shortcut for doing this...
    # template = loader.get_template('testApp/index.html')
    # return HttpResponse(template.render(context, request))

    return render(request, 'testApp/index.html', context)
    # return HttpResponse('This is an HttpResponse.')


def status(request):
    context = {}
    return render(request, 'testApp/status.html', context)
